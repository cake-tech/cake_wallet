import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/input_ownership.dart';
// import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';

/// Parses raw tx hex found in [verboseByHash] (under the `hex` key) into
/// [BtcTransaction]s. Runs entirely in a throwaway background Isolate.
Future<Map<String, BtcTransaction>> parseTransactions(
  Map<String, Map<String, dynamic>> verboseByHash,
) async {
  final hexByTxId = <String, String>{};
  for (final entry in verboseByHash.entries) {
    final hex = entry.value['hex'] as String?;
    if (hex != null && hex.isNotEmpty) {
      hexByTxId[entry.key] = hex;
    }
  }
  if (hexByTxId.isEmpty) {
    return {};
  }

  final (parsed, failed) = await Isolate.run(() => _parseTransactionsSync(hexByTxId));

  // for (final txId in failed) {
  //   printV('parseTransactions: BtcTransaction.fromRaw failed for '
  //       'txid=$txId (hexLength=${hexByTxId[txId]?.length})');
  // }

  return parsed;
}

(Map<String, BtcTransaction>, List<String>) _parseTransactionsSync(
  Map<String, String> hexByTxId,
) {
  final parsed = <String, BtcTransaction>{};
  final failed = <String>[];
  for (final entry in hexByTxId.entries) {
    try {
      parsed[entry.key] = BtcTransaction.fromRaw(entry.value);
    } catch (_) {
      failed.add(entry.key);
    }
  }
  return (parsed, failed);
}

/// Returns the account owning [bundle] - the first account found among its
/// inputs, then its outputs - or null when none (or not a bitcoin wallet).
/// [derived] must have been derived against every account's addresses.
int? accountForTransaction(
  ElectrumTransactionBundle bundle,
  DerivedTransactionAddresses derived,
  Map<int, Set<String>> addressesByAccount,
  BasedUtxoNetwork network,
  WalletType walletType,
) {
  if (walletType != WalletType.bitcoin) return null;

  int? accountForAddress(String address) {
    for (final entry in addressesByAccount.entries) {
      if (entry.value.contains(address)) return entry.key;
    }
    return null;
  }

  for (var i = 0; i < bundle.originalTransaction.inputs.length; i++) {
    final spentOutput = spentOutputAt(bundle.originalTransaction, bundle.ins, i);

    // Parent not fetched yet: the address is still known from the input's
    // own scriptSig/witness, so a send-all (no change output) still gets
    // attributed to its account instead of vanishing from filtered history.
    final inputAddress = spentOutput != null
        ? addressFromOutputScript(spentOutput.scriptPubKey, network)
        : derived.inputOwnership[i].address;
    if (inputAddress == null) continue;

    final account = accountForAddress(inputAddress);
    if (account != null) return account;
  }

  for (final outputAddress in derived.outputAddresses) {
    final account = accountForAddress(outputAddress);
    if (account != null) return account;
  }

  return null;
}

/// Above this many inputs, a single tx's address derivation / info build is
/// worth a background Isolate.
const int maxInputsToProcessInline = 50;

/// Derives [DerivedTransactionAddresses] for [transaction] in a background
/// Isolate - for a large tx that's hundreds of pubkey address derivations.
Future<DerivedTransactionAddresses> deriveTransactionAddressesInIsolate(
  BtcTransaction transaction,
  Set<String> addresses,
  BasedUtxoNetwork network,
) =>
    Isolate.run(() => DerivedTransactionAddresses.derive(transaction, addresses, network));

/// Builds an [ElectrumTransactionInfo] for every bundle in [args], running
/// entirely in a background Isolate: `fromElectrumBundle` re-derives
/// ownership/addresses for every input and output of a transaction, and
/// doing that for up to a chunk's worth of transactions back to back. One
/// isolate spawn per chunk, not per transaction, keeps the (much more common)
/// case of small, ordinary transactions cheap.
///
/// For bitcoin wallets each transaction's owning account is resolved and its
/// info is built against that account's addresses (falling back to
/// `addresses` when no account owns it).
///
/// `derivedByHash` holds [DerivedTransactionAddresses] already derived
/// against `addresses` (see [deriveTransactionAddressesInIsolate]); any
/// transaction missing from it is derived here.
Future<Map<String, ElectrumTransactionInfo>> buildElectrumTransactionInfosInIsolate(
  (
    Map<String, ElectrumTransactionBundle> bundlesByHash,
    WalletType walletType,
    BasedUtxoNetwork network,
    Set<String> addresses,
    Map<int, Set<String>> addressesByAccount,
    Map<String, int?>? heightsByHash,
  ) args, {
  Map<String, DerivedTransactionAddresses>? derivedByHash,
}) =>
    Isolate.run(() => buildElectrumTransactionInfos(args, derivedByHash));

/// Synchronous [buildElectrumTransactionInfosInIsolate]. Cheaper than the
/// isolate for a single tx whose addresses are already in `derivedByHash`:
/// spawning one deep-copies every bundle (including all parent txs) on the
/// calling isolate, which costs more than the build itself.
Map<String, ElectrumTransactionInfo> buildElectrumTransactionInfos(
  (
    Map<String, ElectrumTransactionBundle> bundlesByHash,
    WalletType walletType,
    BasedUtxoNetwork network,
    Set<String> addresses,
    Map<int, Set<String>> addressesByAccount,
    Map<String, int?>? heightsByHash,
  ) args,
  Map<String, DerivedTransactionAddresses>? derivedByHash,
) {
  final (bundlesByHash, walletType, network, addresses, addressesByAccount, heightsByHash) = args;
  final result = <String, ElectrumTransactionInfo>{};
  for (final entry in bundlesByHash.entries) {
    try {
      final derived = derivedByHash?[entry.key] ??
          DerivedTransactionAddresses.derive(entry.value.originalTransaction, addresses, network);
      final owner =
          accountForTransaction(entry.value, derived, addressesByAccount, network, walletType);
      final info = ElectrumTransactionInfo.fromElectrumBundle(
        entry.value,
        walletType,
        network,
        addresses: owner != null ? addressesByAccount[owner]! : addresses,
        height: heightsByHash?[entry.key],
        derived: derived,
      );
      info.id = entry.key;
      info.accountIndex = owner;
      result[entry.key] = info;
    } catch (_) {}
  }
  return result;
}
