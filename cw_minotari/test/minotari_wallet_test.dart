import 'dart:io';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/exceptions/cake_exception.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_wallet_service.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:flutter_test/flutter_test.dart';

OutputInfo _output({String address = 'addr', int amount = 0, bool sendAll = false, String? note}) =>
    OutputInfo(
      address: address,
      sendAll: sendAll,
      isParsedAddress: false,
      cryptoAmount: Money.fromInt(amount, CryptoCurrency.xtm),
      note: note,
    );

/// Writes plain text, failing on the path given in [failOn].
class _FakeEncryptionFileUtils extends EncryptionFileUtils {
  _FakeEncryptionFileUtils({this.failOn});

  final String? failOn;

  @override
  Future<void> write({required String path, required String password, required String data}) {
    if (path == failOn) throw const FileSystemException('disk full');
    return File(path).writeAsString(data);
  }

  @override
  Future<String> read({required String path, required String password}) =>
      File(path).readAsString();
}

void main() {
  group('minotariSyncStatusFor', () {
    SyncStatus? statusFor(ScanEventDto event, {bool caughtUp = false}) =>
        minotariSyncStatusFor(event, startHeight: 100, caughtUp: caughtUp);

    ScanEventDto progress(int current, int tip) => ScanEventDto.progress(
          accountId: 1,
          currentHeight: BigInt.from(current),
          tipHeight: BigInt.from(tip),
          blocksScanned: BigInt.one,
        );

    test('progress reports the percentage towards the tip', () {
      final status = statusFor(ScanEventDto.progress(
        accountId: 1,
        currentHeight: BigInt.from(150),
        tipHeight: BigInt.from(200),
        blocksScanned: BigInt.from(50),
      ));

      expect(status, isA<SyncingSyncStatus>());
      expect(status!.progress(), 0.5);
    });

    test('before catching up, progress near the tip is still syncing', () {
      expect(statusFor(progress(199, 200)), isA<SyncingSyncStatus>());
    });

    test('once caught up, it stays synced within 2 blocks of the tip', () {
      expect(statusFor(progress(198, 200), caughtUp: true), isA<SyncedSyncStatus>());
      expect(statusFor(progress(197, 200), caughtUp: true), isA<SyncingSyncStatus>());
    });

    test('only a caught-up or completed scan is synced', () {
      expect(statusFor(ScanEventDto.waiting(accountId: 1, resumeInSeconds: BigInt.from(60))),
          isA<SyncedSyncStatus>());
      expect(
          statusFor(ScanEventDto.completed(
              accountId: 1, finalHeight: BigInt.one, totalBlocksScanned: BigInt.one)),
          isA<SyncedSyncStatus>());
      expect(statusFor(ScanEventDto.started(accountId: 1, fromHeight: BigInt.zero)),
          isNot(isA<SyncedSyncStatus>()));
    });

    test('a stopped or replaced scan is not connected, an error fails', () {
      expect(statusFor(const ScanEventDto.cancelled()), isA<NotConnectedSyncStatus>());
      expect(statusFor(const ScanEventDto.superseded()), isA<NotConnectedSyncStatus>());
      expect(statusFor(const ScanEventDto.error('transport error')), isA<FailedSyncStatus>());
    });

    test('blocks and transaction events leave the status alone', () {
      expect(
          statusFor(ScanEventDto.moreBlocksAvailable(accountId: 1, lastScannedHeight: BigInt.one)),
          isNull);
    });
  });

  group('minotariRecipients', () {
    test('maps every output and never sends the private note', () {
      final recipients = minotariRecipients([
        _output(address: 'a', amount: 1000, note: 'invoice 7'),
        _output(address: 'b', amount: 2000),
      ]);

      expect(recipients.map((r) => r.address), ['a', 'b']);
      expect(recipients.map((r) => r.amount), [BigInt.from(1000), BigInt.from(2000)]);
      expect(recipients.map((r) => r.paymentId), [null, null]);
    });

    test('send-all pays one recipient and passes no amount', () {
      final recipients = minotariRecipients([_output(sendAll: true, amount: 5000)]);

      expect(recipients.single.amount, BigInt.zero);
    });

    test('rejects send-all combined with other outputs', () {
      expect(
        () => minotariRecipients([_output(sendAll: true), _output(amount: 1)]),
        throwsA(isA<TransactionGenerationException>()),
      );
    });

    test('rejects a zero amount and no outputs', () {
      expect(() => minotariRecipients([_output()]), throwsA(isA<TransactionGenerationException>()));
      expect(() => minotariRecipients([]), throwsA(isA<TransactionGenerationException>()));
    });
  });

  group('writeMinotariKeysFiles', () {
    late Directory dir;
    late String keysPath;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('minotari_keys');
      keysPath = '${dir.path}/wallet.keys';
      File(keysPath).writeAsStringSync('old');
      File('$keysPath.backup').writeAsStringSync('old');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    List<String> files() => dir.listSync().map((f) => f.path.split('/').last).toList()..sort();

    test('replaces both files and leaves no temp files', () async {
      await writeMinotariKeysFiles(_FakeEncryptionFileUtils(),
          keysPath: keysPath, password: 'pw', data: 'new');

      expect(File(keysPath).readAsStringSync(), 'new');
      expect(File('$keysPath.backup').readAsStringSync(), 'new');
      expect(files(), ['wallet.keys', 'wallet.keys.backup']);
    });

    test('a failed write keeps both originals and removes the temp files', () async {
      final writer = _FakeEncryptionFileUtils(failOn: '$keysPath.backup.tmp');

      await expectLater(
        writeMinotariKeysFiles(writer, keysPath: keysPath, password: 'pw', data: 'new'),
        throwsA(isA<FileSystemException>()),
      );
      expect(File(keysPath).readAsStringSync(), 'old');
      expect(File('$keysPath.backup').readAsStringSync(), 'old');
      expect(files(), ['wallet.keys', 'wallet.keys.backup']);
    });
  });

  group('copyMinotariKeysFiles', () {
    late Directory dir;
    late String fromPath;
    late String toPath;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('minotari_rename');
      fromPath = '${dir.path}/old/old';
      toPath = '${dir.path}/new/new';
      Directory('${dir.path}/old').createSync();
      File('$fromPath.keys').writeAsStringSync('old keys');
      File('$fromPath.keys.backup').writeAsStringSync('old backup');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('copies both files and returns the copies', () async {
      final copies = await copyMinotariKeysFiles(fromPath: fromPath, toPath: toPath);

      expect(copies.map((f) => f.path), ['$toPath.keys', '$toPath.keys.backup']);
      expect(File('$toPath.keys').readAsStringSync(), 'old keys');
      expect(File('$fromPath.keys').existsSync(), isTrue);
    });

    test('never overwrites files already under the new name', () async {
      Directory('${dir.path}/new').createSync();
      File('$toPath.keys.backup').writeAsStringSync('leftover');

      await expectLater(
        copyMinotariKeysFiles(fromPath: fromPath, toPath: toPath),
        throwsA(isA<WalletExistsException>()),
      );
      expect(File('$toPath.keys.backup').readAsStringSync(), 'leftover');
      expect(File('$toPath.keys').existsSync(), isFalse);
    });
  });
}
