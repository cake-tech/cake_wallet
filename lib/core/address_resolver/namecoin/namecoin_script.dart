import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class NamecoinNameValue {
  const NamecoinNameValue({required this.name, required this.value});

  final String name;
  final String value;
}

class NamecoinScript {
  static const nameExpireDepth = 36000;

  static Uint8List buildNameIndexScript(String name) {
    final nameBytes = ascii.encode(name);
    return Uint8List.fromList([0x53, ..._pushData(nameBytes), 0x00, 0x6d, 0x75, 0x6a]);
  }

  static String scriptHash(String name) {
    final digest = sha256.convert(buildNameIndexScript(name)).bytes;
    return hex.encode(digest.reversed.toList(growable: false));
  }

  static NamecoinNameValue? fromVerboseTransaction(
    Map<String, dynamic> transaction,
    String expectedName,
  ) {
    final vout = transaction['vout'];
    if (vout is! List) return null;

    for (final output in vout) {
      if (output is! Map<String, dynamic>) continue;
      final scriptPubKey = output['scriptPubKey'];
      if (scriptPubKey is! Map<String, dynamic>) continue;
      final scriptHex = scriptPubKey['hex'];
      if (scriptHex is! String) continue;

      final parsed = _parseNameScript(scriptHex);
      if (parsed != null && parsed.name == expectedName) return parsed;
    }

    return null;
  }

  static NamecoinNameValue? _parseNameScript(String scriptHex) {
    try {
      final script = hex.decode(scriptHex);
      if (script.isEmpty || (script[0] != 0x52 && script[0] != 0x53)) return null;

      final operation = script[0];
      final name = _readPush(script, 1);
      if (name == null) return null;

      var nextOffset = name.nextOffset;
      if (operation == 0x52) {
        final random = _readPush(script, nextOffset);
        if (random == null) return null;
        nextOffset = random.nextOffset;
      }

      final value = _readPush(script, nextOffset);
      if (value == null) return null;

      final dropCount = operation == 0x52 ? 3 : 2;
      if (value.nextOffset + dropCount > script.length) return null;
      if (script[value.nextOffset] != 0x6d) return null;
      if (operation == 0x52) {
        // NAME_FIRSTUPDATE drops all three arguments with two OP_2DROP opcodes.
        if (script[value.nextOffset + 1] != 0x6d) return null;
      } else if (script[value.nextOffset + 1] != 0x75) {
        return null;
      }

      return NamecoinNameValue(name: ascii.decode(name.data), value: utf8.decode(value.data));
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  static List<int> _pushData(List<int> data) {
    if (data.length < 0x4c) return [data.length, ...data];
    if (data.length <= 0xff) return [0x4c, data.length, ...data];
    if (data.length <= 0xffff) {
      return [0x4d, data.length & 0xff, data.length >> 8, ...data];
    }
    throw ArgumentError.value(data.length, 'data', 'Namecoin push data is too large');
  }

  static _PushData? _readPush(List<int> script, int offset) {
    if (offset >= script.length) return null;
    final opcode = script[offset++];
    var length = opcode;

    if (opcode == 0x4c) {
      if (offset >= script.length) return null;
      length = script[offset++];
    } else if (opcode == 0x4d) {
      if (offset + 1 >= script.length) return null;
      length = script[offset] | (script[offset + 1] << 8);
      offset += 2;
    } else if (opcode > 0x4d) {
      return null;
    }

    if (offset + length > script.length) return null;
    return _PushData(Uint8List.fromList(script.sublist(offset, offset + length)), offset + length);
  }
}

class _PushData {
  const _PushData(this.data, this.nextOffset);

  final Uint8List data;
  final int nextOffset;
}
