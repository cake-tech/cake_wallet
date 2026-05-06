import 'dart:typed_data';

import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_starknet/starknet_rust.dart';
import 'package:cw_starknet/starknet_wallet.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
// ignore: implementation_imports
import 'package:ledger_flutter_plus/src/operations/ledger_simple_operation.dart';

class StarknetLedgerService extends HardwareWalletService {
  StarknetLedgerService(this.ledgerConnection);

  static const int _claStarknet = 0x5a;
  static const int _insGetVersion = 0x00;
  static const int _insGetPublicKey = 0x01;
  static const int _insSignHash = 0x02;
  static const String defaultDerivationPathPrefix =
      "m/2645'/1195502025'/1470455285'/0'/0'";

  final LedgerConnection ledgerConnection;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({
    int index = 0,
    int limit = 5,
  }) async {
    await ensureStarknetRustInitialized();
    await _getVersion();

    final accounts = <HardwareAccountData>[];
    final end = index + limit;

    for (var accountIndex = index; accountIndex < end; accountIndex++) {
      final derivationPath = "$defaultDerivationPathPrefix/$accountIndex";
      final publicKey = await getPublicKeyHex(derivationPath: derivationPath);
      final response = await rust_api.deriveAccountFromPublicKey(
        publicKeyHex: publicKey,
        accountClassHashHex: StarknetWalletBase.openZeppelinAccountClassHashHex,
      );
      final accountData = unwrapDerivedAccountDataResponse(response);

      accounts.add(
        HardwareAccountData(
          address: accountData.accountAddressHex,
          publicKey: accountData.publicKeyHex,
          accountIndex: accountIndex,
          derivationPath: derivationPath,
        ),
      );
    }

    return accounts;
  }

  Future<String> getPublicKeyHex({
    required String derivationPath,
    bool display = false,
  }) async {
    final pathBytes = _encodeDerivationPath(derivationPath);
    final response = await _sendSimpleOperation(
      cla: _claStarknet,
      ins: _insGetPublicKey,
      p1: display ? 1 : 0,
      p2: 0,
      data: pathBytes,
    );

    final payload = _extractPayload(response);
    if (payload.length != 65) {
      throw Exception(
        'Unexpected Starknet Ledger public key response length: ${payload.length}',
      );
    }

    return _bytesToHex(payload.sublist(1, 33));
  }

  @override
  Future<Uint8List> signMessage({
    required Uint8List message,
    String? derivationPath,
  }) async {
    final signPath = derivationPath ?? '$defaultDerivationPathPrefix/0';
    if (message.length != 32) {
      throw Exception(
        'Starknet Ledger signing expects a 32-byte hash, got ${message.length} bytes',
      );
    }

    final pathBytes = _encodeDerivationPath(signPath);
    await _sendSimpleOperation(
      cla: _claStarknet,
      ins: _insSignHash,
      p1: 0,
      p2: 0,
      data: pathBytes,
    );

    final version = await _getVersion();
    final adjustedHash = _adjustHashForLegacyApp(message, version);

    final response = await _sendSimpleOperation(
      cla: _claStarknet,
      ins: _insSignHash,
      p1: 1,
      p2: 0,
      data: adjustedHash,
    );

    final payload = _extractPayload(response);
    if (payload.length != 66 || payload.first != 65) {
      throw Exception(
        'Unexpected Starknet Ledger signature response length: ${payload.length}',
      );
    }

    return Uint8List.fromList(payload.sublist(1, 65));
  }

  Future<_LedgerStarknetVersion> _getVersion() async {
    final response = await _sendSimpleOperation(
      cla: _claStarknet,
      ins: _insGetVersion,
      p1: 0,
      p2: 0,
      data: Uint8List(0),
    );

    final payload = _extractPayload(response);
    if (payload.length != 3) {
      throw Exception(
        'Unexpected Starknet Ledger version response length: ${payload.length}',
      );
    }

    return _LedgerStarknetVersion(
      major: payload[0],
      minor: payload[1],
      patch: payload[2],
    );
  }

  Future<Uint8List> _sendSimpleOperation({
    required int cla,
    required int ins,
    required int p1,
    required int p2,
    required Uint8List data,
  }) async {
    final reader = await ledgerConnection.sendOperation<ByteDataReader>(
      LedgerSimpleOperation(
        cla: cla,
        ins: ins,
        p1: p1,
        p2: p2,
        data: data,
        prependDataLength: true,
      ),
    );

    return reader.read(reader.remainingLength);
  }

  Uint8List _extractPayload(Uint8List response) {
    if (response.length < 2) {
      throw Exception('Malformed Starknet Ledger response');
    }

    final statusCode = (response[response.length - 2] << 8) | response[response.length - 1];
    if (statusCode != 0x9000) {
      throw Exception(
        'Ledger Starknet app returned status 0x${statusCode.toRadixString(16).padLeft(4, '0')}',
      );
    }

    return Uint8List.sublistView(response, 0, response.length - 2);
  }

  Uint8List _encodeDerivationPath(String derivationPath) {
    final normalized = derivationPath.trim();
    if (!normalized.startsWith('m/')) {
      throw Exception('Invalid Starknet Ledger derivation path: $derivationPath');
    }

    final segments = normalized.substring(2).split('/');
    if (segments.length != 6) {
      throw Exception('Invalid Starknet Ledger derivation path: $derivationPath');
    }

    final bytes = BytesBuilder(copy: false);
    for (final segment in segments) {
      final isHardened = segment.endsWith("'");
      final numericSegment = isHardened ? segment.substring(0, segment.length - 1) : segment;
      final value = int.tryParse(numericSegment);
      if (value == null || value < 0) {
        throw Exception('Invalid Starknet Ledger derivation path segment: $segment');
      }

      final encodedValue = isHardened ? (value | 0x80000000) : value;
      final segmentBytes = ByteData(4)..setUint32(0, encodedValue, Endian.big);
      bytes.add(segmentBytes.buffer.asUint8List());
    }

    return bytes.toBytes();
  }

  Uint8List _adjustHashForLegacyApp(
    Uint8List message,
    _LedgerStarknetVersion version,
  ) {
    if (version >= const _LedgerStarknetVersion._tuple(2, 0, 0)) {
      return message;
    }

    final mask = (BigInt.one << 256) - BigInt.one;
    var value = BigInt.zero;
    for (final byte in message) {
      value = (value << 8) | BigInt.from(byte);
    }
    final shifted = (value << 4) & mask;
    final result = Uint8List(32);
    var remaining = shifted;
    for (var i = 31; i >= 0; i--) {
      result[i] = (remaining & BigInt.from(0xff)).toInt();
      remaining >>= 8;
    }
    return result;
  }

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer('0x');
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}

class _LedgerStarknetVersion implements Comparable<_LedgerStarknetVersion> {
  const _LedgerStarknetVersion({
    required this.major,
    required this.minor,
    required this.patch,
  });

  const _LedgerStarknetVersion._tuple(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(_LedgerStarknetVersion other) {
    if (major != other.major) {
      return major.compareTo(other.major);
    }
    if (minor != other.minor) {
      return minor.compareTo(other.minor);
    }
    return patch.compareTo(other.patch);
  }

  bool operator >=(_LedgerStarknetVersion other) => compareTo(other) >= 0;
}
