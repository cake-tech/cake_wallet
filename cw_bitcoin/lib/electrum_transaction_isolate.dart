import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
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
/// resolved inputs, then its outputs - or null when none (or not a bitcoin wallet).
int? accountForTransaction(
  ElectrumTransactionBundle bundle,
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
    final inputTransaction = bundle.ins[i];
    if (inputTransaction == null) continue;

    final outTransaction = inputTransaction.outputs[bundle.originalTransaction.inputs[i].txIndex];
    final account =
        accountForAddress(addressFromOutputScript(outTransaction.scriptPubKey, network));
    if (account != null) return account;
  }

  for (final out in bundle.originalTransaction.outputs) {
    final account = accountForAddress(addressFromOutputScript(out.scriptPubKey, network));
    if (account != null) return account;
  }

  return null;
}

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
Future<Map<String, ElectrumTransactionInfo>> buildElectrumTransactionInfosInIsolate(
  (
    Map<String, ElectrumTransactionBundle> bundlesByHash,
    WalletType walletType,
    BasedUtxoNetwork network,
    Set<String> addresses,
    Map<int, Set<String>> addressesByAccount,
    Map<String, int?>? heightsByHash,
  ) args,
) =>
    Isolate.run(() => _buildElectrumTransactionInfosSync(args));

Map<String, ElectrumTransactionInfo> _buildElectrumTransactionInfosSync(
  (
    Map<String, ElectrumTransactionBundle> bundlesByHash,
    WalletType walletType,
    BasedUtxoNetwork network,
    Set<String> addresses,
    Map<int, Set<String>> addressesByAccount,
    Map<String, int?>? heightsByHash,
  ) args,
) {
  final (bundlesByHash, walletType, network, addresses, addressesByAccount, heightsByHash) = args;
  final result = <String, ElectrumTransactionInfo>{};
  for (final entry in bundlesByHash.entries) {
    try {
      final owner = accountForTransaction(entry.value, addressesByAccount, network, walletType);
      final info = ElectrumTransactionInfo.fromElectrumBundle(
        entry.value,
        walletType,
        network,
        addresses: owner != null ? addressesByAccount[owner]! : addresses,
        height: heightsByHash?[entry.key],
      );
      info.id = entry.key;
      info.accountIndex = owner;
      result[entry.key] = info;
    } catch (_) {}
  }
  return result;
}
