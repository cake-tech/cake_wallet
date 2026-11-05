import 'dart:convert';
import 'dart:typed_data';

import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:on_chain/on_chain.dart';

class TronLedgerException implements Exception {
  TronLedgerException(this.message, [this.status]);
  final String message;
  final int? status;

  @override
  String toString() => status == null
      ? 'TRON Ledger: $message'
      : 'TRON Ledger: $message (0x${status!.toRadixString(16).padLeft(4, '0')})';
}

class TronLedgerConfiguration {
  const TronLedgerConfiguration(this.flags, this.major, this.minor, this.patch);
  final int flags;
  final int major;
  final int minor;
  final int patch;
}

class TronLedgerAddress {
  const TronLedgerAddress(this.publicKey, this.address);
  final Uint8List publicKey;
  final String address;
}

Uint8List encodeTronLedgerPath(String path) {
  final match = RegExp(r"^m/44'/195'/(\d+)'/0/0$").firstMatch(path);
  if (match == null) throw ArgumentError('Invalid TRON Ledger derivation path');
  final account = int.tryParse(match.group(1)!);
  if (account == null || account >= 0x80000000) {
    throw ArgumentError('Invalid TRON Ledger account index');
  }
  final bytes = ByteData(21)..setUint8(0, 5);
  final parts = [0x8000002c, 0x800000c3, 0x80000000 | account, 0, 0];
  for (var i = 0; i < parts.length; i++) {
    bytes.setUint32(1 + i * 4, parts[i], Endian.big);
  }
  return bytes.buffer.asUint8List();
}

/// Split only at complete top-level protobuf fields, as required by app-tron.
List<Uint8List> tronLedgerTransactionChunks(String path, Uint8List raw) {
  if (raw.isEmpty) throw ArgumentError('Empty TRON transaction');
  final chunks = <Uint8List>[];
  var current = <int>[...encodeTronLedgerPath(path)];
  var offset = 0;
  while (offset < raw.length) {
    final start = offset;
    (int, int) readVarint(int at) {
      var value = 0;
      var shift = 0;
      for (var i = 0; i < 10 && at < raw.length; i++) {
        final byte = raw[at++];
        value |= (byte & 0x7f) << shift;
        if ((byte & 0x80) == 0) return (value, at);
        shift += 7;
      }
      throw FormatException('Malformed protobuf varint');
    }

    final (tag, afterTag) = readVarint(offset);
    if (tag >> 3 == 0) throw FormatException('Invalid protobuf field');
    final wire = tag & 7;
    if (wire == 0) {
      offset = readVarint(afterTag).$2;
    } else if (wire == 2) {
      final (length, afterLength) = readVarint(afterTag);
      if (length > raw.length - afterLength) throw FormatException('Truncated protobuf field');
      offset = afterLength + length;
    } else {
      throw FormatException('Unsupported protobuf wire type');
    }
    final fieldLength = offset - start;
    if (fieldLength > 250) throw ArgumentError('TRON transaction field exceeds Ledger APDU limit');
    if (current.length + fieldLength > 250) {
      if (chunks.isEmpty && current.length == 21) {
        throw ArgumentError('First TRON transaction field exceeds Ledger APDU limit');
      }
      chunks.add(Uint8List.fromList(current));
      current = [];
    }
    current.addAll(raw.sublist(start, offset));
  }
  chunks.add(Uint8List.fromList(current));
  return chunks;
}

class _TronApdu extends LedgerRawOperation<Uint8List> {
  _TronApdu(this.ins, this.p1, this.data);
  final int ins;
  final int p1;
  final Uint8List data;

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async {
    writer
      ..writeUint8(0xe0)
      ..writeUint8(ins)
      ..writeUint8(p1)
      ..writeUint8(0)
      ..writeUint8(data.length)
      ..write(data);
    return [writer.toBytes()];
  }

  @override
  Future<Uint8List> read(ByteDataReader reader) async {
    final bytes = reader.read(reader.remainingLength);
    if (bytes.length < 2) throw TronLedgerException('Malformed device response');
    final status = (bytes[bytes.length - 2] << 8) | bytes.last;
    if (status != 0x9000) {
      final message = switch (status) {
        0x6985 => 'Request rejected on device',
        0x6a8a => 'Invalid derivation path',
        0x6a8b => 'Transaction data is not allowed by the TRON app',
        0x6a8c => 'Sign by hash is disabled',
        0x6a8d => 'Unsupported custom contract',
        0x6d00 || 0x6e00 => 'Open the TRON app on the Ledger',
        _ => 'Device rejected the request',
      };
      throw TronLedgerException(message, status);
    }
    return Uint8List.fromList(bytes.sublist(0, bytes.length - 2));
  }
}

class _TronSignOperation extends LedgerComplexOperation<Uint8List> {
  const _TronSignOperation(this.chunks, this.requireClearUsdt);
  final List<Uint8List> chunks;
  final bool requireClearUsdt;

  @override
  Future<Uint8List> invoke(LedgerSendFct send) async {
    if (requireClearUsdt) {
      final config = await send(_TronApdu(0x06, 0, Uint8List(0)));
      if (config.length != 4) throw TronLedgerException('Malformed app configuration');
      if (config[1] == 0 && (config[2] < 8 || (config[2] == 8 && config[3] < 1))) {
        throw TronLedgerException('Update the TRON app to version 0.8.1 or later for USDT');
      }
      if ((config[0] & 0x02) != 0) {
        throw TronLedgerException('Disable custom contract signing in the TRON app for USDT');
      }
    }
    for (var i = 0; i < chunks.length; i++) {
      final p1 = chunks.length == 1
          ? 0x10
          : i == 0
              ? 0
              : i == chunks.length - 1
                  ? 0x90
                  : 0x80;
      final result = await send(_TronApdu(0x04, p1, chunks[i]));
      if (i < chunks.length - 1) {
        if (result.isNotEmpty) throw TronLedgerException('Unexpected intermediate response');
      } else {
        if (result.length != 65 || result[64] > 1) {
          throw TronLedgerException('Invalid transaction signature');
        }
        return result;
      }
    }
    throw TronLedgerException('Empty signing request');
  }
}

class TronLedgerApp {
  TronLedgerApp(this.connection);
  final LedgerConnection connection;

  Future<TronLedgerConfiguration> getAppConfiguration() async {
    final data = await connection.sendOperation(_TronApdu(0x06, 0, Uint8List(0)));
    if (data.length != 4) throw TronLedgerException('Malformed app configuration');
    return TronLedgerConfiguration(data[0], data[1], data[2], data[3]);
  }

  Future<TronLedgerAddress> getAddress(String path, {bool display = false}) async {
    final data = await connection.sendOperation(
      _TronApdu(0x02, display ? 1 : 0, encodeTronLedgerPath(path)),
    );
    if (data.length != 101 || data[0] != 65 || data[66] != 34) {
      throw TronLedgerException('Malformed address response');
    }
    final key = Uint8List.fromList(data.sublist(1, 66));
    final address = ascii.decode(data.sublist(67), allowInvalid: false);
    if (TronPublicKey.fromBytes(key).toAddress().toAddress() != address) {
      throw TronLedgerException('Address does not match device public key');
    }
    return TronLedgerAddress(key, address);
  }

  Future<Uint8List> signTransaction(
    String path,
    Uint8List rawData, {
    bool requireClearUsdt = false,
  }) =>
      connection.sendOperation(
        _TronSignOperation(tronLedgerTransactionChunks(path, rawData), requireClearUsdt),
      );
}
