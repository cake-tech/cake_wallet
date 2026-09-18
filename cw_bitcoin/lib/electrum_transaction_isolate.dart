import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
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

/// Builds an [ElectrumTransactionInfo] for every bundle in [args], running
/// entirely in a background Isolate: `fromElectrumBundle` re-derives
/// ownership/addresses for every input and output of a transaction, and
/// doing that for up to a chunk's worth of transactions back to back. One
/// isolate spawn per chunk, not per transaction, keeps the (much more common)
/// case of small, ordinary transactions cheap.
Future<Map<String, ElectrumTransactionInfo>> buildElectrumTransactionInfosInIsolate(
  (
    Map<String, ElectrumTransactionBundle> bundlesByHash,
    WalletType walletType,
    BasedUtxoNetwork network,
    Set<String> addresses,
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
    Map<String, int?>? heightsByHash,
  ) args,
) {
  final (bundlesByHash, walletType, network, addresses, heightsByHash) = args;
  final result = <String, ElectrumTransactionInfo>{};
  for (final entry in bundlesByHash.entries) {
    try {
      final info = ElectrumTransactionInfo.fromElectrumBundle(
        entry.value,
        walletType,
        network,
        addresses: addresses,
        height: heightsByHash?[entry.key],
      );
      info.id = entry.key;
      result[entry.key] = info;
    } catch (_) {}
  }
  return result;
}
