import "dart:math";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/derivation_recovery/recovery_derivations.dart";
import "package:cw_bitcoin/electrum.dart";
import "package:cw_core/utils/print_verbose.dart";

/// An unspent output on a recovery address.
class RecoveryUnspent {
  const RecoveryUnspent({
    required this.hash,
    required this.vout,
    required this.value,
    required this.height,
  });

  factory RecoveryUnspent.fromElectrum(Map<String, dynamic> json) => RecoveryUnspent(
        hash: json["tx_hash"] as String,
        vout: json["tx_pos"] as int,
        value: json["value"] as int,
        height: json["height"] as int? ?? 0,
      );

  final String hash;
  final int vout;
  final int value;
  final int height;
}

/// What the recovery reads from the chain, by Electrum script hash.
abstract class RecoveryChainSource {
  /// The script hashes, out of [scriptHashes], that have any history.
  Future<Set<String>> usedScriptHashes(List<String> scriptHashes);

  /// The unspent outputs of each of [scriptHashes].
  Future<Map<String, List<RecoveryUnspent>>> unspents(List<String> scriptHashes);
}

/// [RecoveryChainSource] over a wallet's Electrum connection, in batches when the server takes them.
class ElectrumRecoveryChainSource implements RecoveryChainSource {
  ElectrumRecoveryChainSource(this.client, {required this.useBatch});

  final ElectrumClient client;
  final bool useBatch;

  static const _chunkSize = 100;

  @override
  Future<Set<String>> usedScriptHashes(List<String> scriptHashes) async {
    final used = <String>{};
    for (final chunk in _chunks(scriptHashes)) {
      final histories = await _query(chunk, client.getBatchHistory, client.getHistory);
      used.addAll(histories.entries.where((entry) => entry.value.isNotEmpty).map((e) => e.key));
    }
    return used;
  }

  @override
  Future<Map<String, List<RecoveryUnspent>>> unspents(List<String> scriptHashes) async {
    final result = <String, List<RecoveryUnspent>>{};
    for (final chunk in _chunks(scriptHashes)) {
      final unspents = await _query(
        chunk,
        client.getBatchUnspent,
        (scriptHash) async => await client.getListUnspent(scriptHash) ?? [],
      );
      unspents.forEach(
        (scriptHash, outputs) =>
            result[scriptHash] = outputs.map(RecoveryUnspent.fromElectrum).toList(),
      );
    }
    return result;
  }

  // One batch request when the server takes batches; otherwise, or when the batch fails, one
  // request per script hash, sent together.
  Future<Map<String, List<Map<String, dynamic>>>> _query(
    List<String> chunk,
    Future<Map<String, List<Map<String, dynamic>>>> Function(List<String>) batch,
    Future<List<Map<String, dynamic>>> Function(String) single,
  ) async {
    if (useBatch) {
      try {
        return await batch(chunk);
      } catch (e) {
        printV("Derivation recovery: batch request failed, retrying one by one: $e");
      }
    }

    final results = await Future.wait(chunk.map(single));
    return {for (var i = 0; i < chunk.length; i++) chunk[i]: results[i]};
  }

  Iterable<List<String>> _chunks(List<String> items) sync* {
    for (var i = 0; i < items.length; i += _chunkSize) {
      yield items.sublist(i, min(i + _chunkSize, items.length));
    }
  }
}

/// An address on a recovery chain.
class RecoveryAddress {
  RecoveryAddress(this.chain, this.index, this.type, this.address, this.scriptHash);

  final RecoveryChain chain;
  final int index;
  final BitcoinAddressType type;
  final String address;
  final String scriptHash;
}

/// Finds the used addresses on recovery chains: the first [depth] of every chain, then [gap] past
/// the last used one for as long as that finds more, like a wallet's own discovery.
class RecoveryScanner {
  RecoveryScanner({
    required this.masters,
    required this.chains,
    required this.network,
    required this.source,
    this.depth = 200,
    this.gap = 20,
    this.maxDepth = 10000,
    this.onProgress,
  });

  final RecoveryMasters masters;
  final List<RecoveryChain> chains;
  final BasedUtxoNetwork network;
  final RecoveryChainSource source;
  final int depth;
  final int gap;
  final int maxDepth;

  /// Called with the number of addresses checked so far.
  final void Function(int checkedAddresses)? onProgress;

  Future<List<RecoveryAddress>> usedAddresses() async {
    final slice = Stopwatch()..start();
    final hds = {for (final chain in chains) chain: chain.hd(masters)};
    final scannedTo = {for (final chain in chains) chain: 0};
    final highestUsed = {for (final chain in chains) chain: -1};
    final used = <RecoveryAddress>[];
    var checked = 0;

    var scanTo = {for (final chain in chains) chain: min(depth, maxDepth)};
    while (scanTo.isNotEmpty) {
      final candidates = <RecoveryAddress>[];
      for (final entry in scanTo.entries) {
        final chain = entry.key;
        for (var index = scannedTo[chain]!; index < entry.value; index++) {
          // One derivation per index, encoded as each of the chain's address types.
          final publicKey =
              ECPublic.fromBip32(hds[chain]!.childKey(Bip32KeyIndex(index)).publicKey);
          for (final type in chain.addressTypes) {
            final address = addressForPublicKey(publicKey, type, network);
            final scriptHash = BitcoinAddressUtils.scriptHash(address, network: network);
            candidates.add(RecoveryAddress(chain, index, type, address, scriptHash));
          }
          await yieldIfSliceElapsed(slice);
        }
        scannedTo[chain] = entry.value;
      }

      final usedScriptHashes =
          await source.usedScriptHashes([for (final candidate in candidates) candidate.scriptHash]);
      for (final candidate in candidates) {
        if (usedScriptHashes.contains(candidate.scriptHash)) {
          used.add(candidate);
          highestUsed[candidate.chain] = max(highestUsed[candidate.chain]!, candidate.index);
        }
      }

      checked += candidates.length;
      onProgress?.call(checked);

      scanTo = {
        for (final chain in chains)
          if (highestUsed[chain]! + gap >= scannedTo[chain]! && scannedTo[chain]! < maxDepth)
            chain: min(highestUsed[chain]! + gap + 1, maxDepth),
      };
    }

    return used;
  }
}
