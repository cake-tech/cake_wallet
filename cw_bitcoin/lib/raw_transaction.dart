import 'dart:math';

import 'package:blockchain_utils/blockchain_utils.dart';

/// Parses a raw transaction hex (with or without segwit witnesses) and returns
/// its txid - the double SHA-256 of the serialization without witnesses - and
/// each input's witness stack. Null when the hex isn't a well-formed transaction.
///
/// The txid is computed from the bytes, not from a parse through bitcoin_base,
/// so a node's data can be checked against the txid it was asked for.
({String txId, List<List<List<int>>> witnesses})? parseRawTransaction(String? hex) {
  try {
    final raw = BytesUtils.fromHexString(hex!);
    final isSegwit = raw[4] == 0 && raw[5] == 1;
    var cursor = isSegwit ? 6 : 4;
    final bodyStart = cursor;
    int readVarint() {
      final value = IntUtils.decodeVarint(raw.sublist(cursor, min(cursor + 9, raw.length)));
      cursor += value.item2;
      return value.item1;
    }

    final inputCount = readVarint();
    for (var i = 0; i < inputCount; i++) {
      cursor += 36;
      final scriptLength = readVarint();
      cursor += scriptLength + 4;
    }
    final outputCount = readVarint();
    for (var i = 0; i < outputCount; i++) {
      cursor += 8;
      final scriptLength = readVarint();
      cursor += scriptLength;
    }
    final body = raw.sublist(bodyStart, cursor);

    final witnesses = <List<List<int>>>[];
    for (var i = 0; isSegwit && i < inputCount; i++) {
      final stack = <List<int>>[];
      final itemCount = readVarint();
      for (var j = 0; j < itemCount; j++) {
        final length = readVarint();
        stack.add(raw.sublist(cursor, cursor + length));
        cursor += length;
      }
      witnesses.add(stack);
    }
    if (cursor + 4 != raw.length) return null;

    final hash =
        QuickCrypto.sha256DoubleHash([...raw.sublist(0, 4), ...body, ...raw.sublist(cursor)]);
    return (txId: BytesUtils.toHexString(hash.reversed.toList()), witnesses: witnesses);
  } catch (_) {
    return null;
  }
}
