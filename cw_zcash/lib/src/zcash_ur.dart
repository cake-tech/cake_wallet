import 'dart:typed_data';

import 'package:ur/ur.dart';
import 'package:ur/ur_decoder.dart';
import 'package:ur/ur_encoder.dart';
import 'package:zkool/src/zcash_ur.dart';

export 'package:zkool/src/zcash_ur.dart'
    show ZcashUrAccount, ZcashUrAccounts, zcashAccountsType, zcashPcztType;

const zcashPcztFragmentLength = 120;

List<String> encodeZcashPcztUr(Uint8List pczt, {int fragmentLength = zcashPcztFragmentLength}) {
  final encoder = UREncoder(UR(zcashPcztType, encodeZcashPczt(pczt)), fragmentLength);
  final parts = <String>[];
  while (!encoder.isComplete) {
    parts.add(encoder.nextPart());
  }
  return parts;
}

Uint8List cborFromUrParts(List<String> parts) {
  final decoder = URDecoder();
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    decoder.receivePart(trimmed);
  }
  if (!decoder.isSuccess()) {
    throw const FormatException('Incomplete Zcash QR');
  }
  return (decoder.result as UR).cbor;
}

Uint8List decodeZcashPcztUr(List<String> parts) => decodeZcashPczt(cborFromUrParts(parts));

ZcashUrAccounts decodeZcashAccountsUr(List<String> parts) =>
    decodeZcashAccounts(cborFromUrParts(parts));
