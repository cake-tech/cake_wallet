import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:ledger_bitcoin/src/psbt/keypair.dart';
import 'package:ledger_bitcoin/src/utils/buffer_writer.dart';

extension PsbtGetAndSet on Map {
  Uint8List? get(
    int keyType,
    Uint8List keyData, [
    bool acceptUndefined = false,
  ]) {
    final key = Key(keyType, keyData);
    final value = this[key.toString()];
    if (value == null && !acceptUndefined) {
      throw Exception(key.toString());
    }
    // Make sure to return a copy, to protect the underlying data.
    return value as Uint8List?;
  }

  void set(int keyType, Uint8List keyData, Uint8List value) {
    final key = Key(keyType, keyData);
    this[key.toString()] = value;
  }

  void serializeMap(BufferWriter buf) {
    for (final k in keys) {
      final value = this[k] as Uint8List;
      final keyPair =
          KeyPair(_createKey(hex.decode(k.toString()) as Uint8List), value);
      keyPair.serialize(buf);
    }
    buf.writeUInt8(0);
  }

  Key _createKey(Uint8List buf) => Key(buf[0], buf.sublist(1));
}
