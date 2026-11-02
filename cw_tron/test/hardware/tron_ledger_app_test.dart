import 'dart:async';
import 'dart:typed_data';

import 'package:cw_tron/hardware/tron_ledger_app.dart';
import 'package:cw_tron/hardware/tron_ledger_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus_dart.dart';
import 'package:on_chain/on_chain.dart';
import 'package:blockchain_utils/blockchain_utils.dart' show BytesUtils, QuickCrypto;
import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';

class _Device implements LedgerDevice {
  @override
  String get id => 'test-ledger';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ConnectionManager implements ConnectionManager {
  final calls = <Uint8List>[];
  final responses = <Uint8List>[];
  int? disconnectAtCall;
  Completer<void>? firstStarted;
  Completer<void>? releaseFirst;

  @override
  ConnectionType get connectionType => ConnectionType.ble;

  @override
  Stream<BleConnectionState> deviceStateChanges(String deviceId) => const Stream.empty();

  @override
  Future<T> sendRawOperation<T>(
    LedgerDevice device,
    LedgerRawOperation<T> operation,
    LedgerTransformer? transformer,
  ) async {
    final requests = await operation.write(ByteDataWriter());
    calls.addAll(requests);
    if (calls.length == 1 && firstStarted != null) {
      firstStarted!.complete();
      await releaseFirst!.future;
    }
    if (calls.length == disconnectAtCall) throw StateError('Device disconnected');
    final reader = ByteDataReader()..add(responses.removeAt(0));
    return operation.read(reader);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Uint8List _response(List<int> data, [int status = 0x9000]) =>
    Uint8List.fromList([...data, status >> 8, status & 0xff]);

void main() {
  group('TRON Ledger APDUs', () {
    late _ConnectionManager manager;
    late TronLedgerApp app;

    setUp(() {
      manager = _ConnectionManager();
      app = TronLedgerApp(LedgerConnection(manager, _Device()));
    });

    test('concurrent operations cannot interleave with a multi-APDU signature', () async {
      manager.firstStarted = Completer<void>();
      manager.releaseFirst = Completer<void>();
      manager.responses.addAll([
        _response([]),
        _response([...List.filled(64, 1), 0]),
        _response([0, 0, 8, 1]),
      ]);
      final raw = Uint8List.fromList([
        0x0a,
        220,
        1,
        ...List.filled(220, 7),
        0x12,
        10,
        ...List.filled(10, 8),
      ]);
      final signing = app.signTransaction("m/44'/195'/0'/0/0", raw);
      await manager.firstStarted!.future;
      final configuration = app.getAppConfiguration();
      await Future<void>.delayed(Duration.zero);
      expect(manager.calls.map((call) => call[1]), [0x04]);
      manager.releaseFirst!.complete();
      await signing;
      await configuration;
      expect(manager.calls.map((call) => call[1]), [0x04, 0x04, 0x06]);
    });

    test('encodes account paths and rejects invalid indices', () {
      expect(encodeTronLedgerPath("m/44'/195'/0'/0/0"), [
        5,
        0x80,
        0,
        0,
        44,
        0x80,
        0,
        0,
        195,
        0x80,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ]);
      expect(encodeTronLedgerPath("m/44'/195'/1'/0/0")[12], 1);
      expect(() => encodeTronLedgerPath("m/44'/195'/2147483648'/0/0"), throwsArgumentError);
      expect(() => encodeTronLedgerPath("m/44'/60'/0'/0/0"), throwsArgumentError);
    });

    test('enumerates distinct accounts and validates device public keys', () async {
      List<int> addressResponse(int index) {
        final key = TronPrivateKey(index.toRadixString(16).padLeft(64, '0')).publicKey();
        return [
          65,
          ...key.toBytes(PubKeyModes.uncompressed),
          34,
          ...key.toAddress().toAddress().codeUnits
        ];
      }

      manager.responses.addAll([
        _response([0, 1, 2, 3]),
        _response(addressResponse(1)),
        _response(addressResponse(2)),
      ]);
      final service = TronLedgerService(LedgerConnection(manager, _Device()));
      final accounts = await service.getAvailableAccounts(index: 0, limit: 2);
      expect(accounts.map((a) => a.derivationPath), ["m/44'/195'/0'/0/0", "m/44'/195'/1'/0/0"]);
      expect(accounts[0].address, isNot(accounts[1].address));
      expect(manager.calls[1][17], 0);
      expect(manager.calls[2][17], 1);
    });

    test('checks status words and malformed configuration', () async {
      manager.responses.add(_response([], 0x6985));
      await expectLater(app.getAppConfiguration(), throwsA(isA<TronLedgerException>()));
      manager.responses.add(_response([0]));
      await expectLater(app.getAppConfiguration(), throwsA(isA<TronLedgerException>()));
    });

    test('recovers the signer from both Ledger parity values over raw transaction bytes', () {
      final raw = Uint8List.fromList([0x08, 1, 0x10, 2]);
      final parities = <int>{};
      for (var i = 1; i <= 32 && parities.length < 2; i++) {
        final key = TronPrivateKey(i.toRadixString(16).padLeft(64, '0'));
        final signature = Uint8List.fromList(key.sign(raw))..[64] -= 27;
        parities.add(signature.last);
        final recovered = TronPublicKey.fromPersonalSignature(
          QuickCrypto.sha256Hash(raw),
          BytesUtils.toHexString(signature),
          hashMessage: false,
        );
        expect(recovered!.toAddress().toAddress(), key.publicKey().toAddress().toAddress());
      }
      expect(parities, {0, 1});
    });

    test('address verification displays and compares the device address', () async {
      final key = TronPrivateKey('01'.padLeft(64, '0')).publicKey();
      final address = key.toAddress().toAddress();
      final response = [
        65,
        ...key.toBytes(PubKeyModes.uncompressed),
        34,
        ...address.codeUnits,
      ];
      final service = TronLedgerService(LedgerConnection(manager, _Device()));
      manager.responses.add(_response(response));
      await service.verifyAddress("m/44'/195'/1'/0/0", address);
      expect(manager.calls.single[2], 1);
      manager.responses.add(_response(response));
      await expectLater(
          service.verifyAddress("m/44'/195'/1'/0/0", 'wrong'), throwsA(isA<TronLedgerException>()));
    });

    test('rejected and malformed signing responses do not produce a signature', () async {
      final raw = Uint8List.fromList([0x08, 1]);
      manager.responses.add(_response([], 0x6985));
      await expectLater(
          app.signTransaction("m/44'/195'/0'/0/0", raw), throwsA(isA<TronLedgerException>()));
      manager.responses.add(_response([...List.filled(64, 1), 27]));
      await expectLater(
          app.signTransaction("m/44'/195'/0'/0/0", raw), throwsA(isA<TronLedgerException>()));
      expect(manager.calls.every((call) => call[1] == 0x04 && call[2] == 0x10), isTrue);
    });

    test('requires a supported app and disables custom-contract fallback for USDT', () async {
      final raw = Uint8List.fromList([0x08, 1]);
      manager.responses.add(_response([0, 0, 8, 0]));
      await expectLater(
        app.signTransaction("m/44'/195'/0'/0/0", raw, requireClearUsdt: true),
        throwsA(isA<TronLedgerException>()),
      );
      manager.responses.add(_response([2, 0, 8, 1]));
      await expectLater(
        app.signTransaction("m/44'/195'/0'/0/0", raw, requireClearUsdt: true),
        throwsA(isA<TronLedgerException>()),
      );
      manager.responses.addAll([
        _response([0, 0, 8, 1]),
        _response([...List.filled(64, 1), 0]),
      ]);
      await app.signTransaction("m/44'/195'/0'/0/0", raw, requireClearUsdt: true);
      expect(manager.calls.map((call) => call[1]), [0x06, 0x06, 0x06, 0x04]);
    });

    test('streams complete fields and validates final signature', () async {
      final raw = Uint8List.fromList([
        0x0a,
        220,
        1,
        ...List.filled(220, 7),
        0x12,
        10,
        ...List.filled(10, 8),
      ]);
      final chunks = tronLedgerTransactionChunks("m/44'/195'/0'/0/0", raw);
      expect(chunks.length, 2);
      expect(chunks.map((c) => c.length), everyElement(lessThanOrEqualTo(250)));
      manager.responses.addAll([
        _response([]),
        _response([...List.filled(64, 1), 0]),
      ]);
      final signature = await app.signTransaction("m/44'/195'/0'/0/0", raw);
      expect(signature.length, 65);
      expect(manager.calls.map((c) => c[2]), [0, 0x90]);
      expect([...manager.calls[0].sublist(26), ...manager.calls[1].sublist(5)], raw);
    });

    test('stops a multi-APDU exchange on rejection or disconnection', () async {
      final raw = Uint8List.fromList([
        0x0a,
        220,
        1,
        ...List.filled(220, 7),
        0x12,
        10,
        ...List.filled(10, 8),
      ]);
      manager.responses.add(_response([], 0x6985));
      await expectLater(
        app.signTransaction("m/44'/195'/0'/0/0", raw),
        throwsA(isA<TronLedgerException>()),
      );
      expect(manager.calls.length, 1);
      manager.calls.clear();
      manager.responses.add(_response([]));
      manager.disconnectAtCall = 2;
      await expectLater(
        app.signTransaction("m/44'/195'/0'/0/0", raw),
        throwsStateError,
      );
      expect(manager.calls.length, 2);
    });

    test('rejects truncated, unsupported and oversized fields', () {
      expect(
        () => tronLedgerTransactionChunks("m/44'/195'/0'/0/0", Uint8List.fromList([0x0a, 5, 1])),
        throwsFormatException,
      );
      expect(
        () => tronLedgerTransactionChunks(
          "m/44'/195'/0'/0/0",
          Uint8List.fromList([0x0d, 0, 0, 0, 0]),
        ),
        throwsFormatException,
      );
      expect(
        () => tronLedgerTransactionChunks(
          "m/44'/195'/0'/0/0",
          Uint8List.fromList([0x0a, 250, 1, ...List.filled(250, 0)]),
        ),
        throwsArgumentError,
      );
      expect(
        () => tronLedgerTransactionChunks(
          "m/44'/195'/0'/0/0",
          Uint8List.fromList([0x0a, 230, 1, ...List.filled(230, 0)]),
        ),
        throwsArgumentError,
      );
    });
  });
}
