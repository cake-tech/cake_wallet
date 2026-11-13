import 'dart:io';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/exceptions/cake_exception.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:cw_minotari/minotari_send_notes.dart';
import 'package:cw_minotari/minotari_transaction_priority.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_wallet_service.dart';
import 'package:cw_minotari/src/rust/api/scanner.dart';
import 'package:cw_minotari/src/rust/api/send_transaction.dart';
import 'package:cw_minotari/src/rust/api/transactions.dart';
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

    test('a background slot pauses when stopped or out of time, never synced', () {
      SyncStatus? background(ScanEventDto event) =>
          minotariSyncStatusFor(event, startHeight: 100, caughtUp: false, background: true);

      expect(background(const ScanEventDto.cancelled()), isA<PausedSyncStatus>());
      expect(
          background(ScanEventDto.budgetExhausted(
              accountId: 1, lastScannedHeight: BigInt.from(150), tipHeight: BigInt.from(200))),
          isA<PausedSyncStatus>());
      expect(
          background(ScanEventDto.completed(
              accountId: 1, finalHeight: BigInt.one, totalBlocksScanned: BigInt.one)),
          isA<SyncedSyncStatus>());
      expect(background(progress(199, 200)), isA<SyncingSyncStatus>());
    });

    test('a background slot hands over to the app, other errors fail', () {
      SyncStatus? background(ScanEventDto event) =>
          minotariSyncStatusFor(event, startHeight: 100, caughtUp: false, background: true);

      expect(background(const ScanEventDto.superseded()), isA<HandledByForegroundSyncStatus>());
      expect(
          background(const ScanEventDto.error(
              'Scan error: A foreground scan of this wallet is already running')),
          isA<HandledByForegroundSyncStatus>());
      expect(background(const ScanEventDto.error('transport error')), isA<FailedSyncStatus>());
    });

    test('the app never gets the background-only statuses', () {
      for (final event in [
        const ScanEventDto.superseded(),
        const ScanEventDto.cancelled(),
        const ScanEventDto.error('A foreground scan of this wallet is already running'),
      ]) {
        expect(statusFor(event),
            isNot(anyOf(isA<PausedSyncStatus>(), isA<HandledByForegroundSyncStatus>())));
      }
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

    test('copies the send notes too', () async {
      File('$fromPath$minotariSendNotesSuffix').writeAsStringSync('notes');

      final copies = await copyMinotariKeysFiles(fromPath: fromPath, toPath: toPath);

      expect(copies.map((f) => f.path), contains('$toPath$minotariSendNotesSuffix'));
      expect(File('$toPath$minotariSendNotesSuffix').readAsStringSync(), 'notes');
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

  group('runAfterMinotariQueue', () {
    test('a failure neither fails the caller nor blocks later work', () async {
      final ran = <String>[];
      var queue = Future<void>.value();
      queue = runAfterMinotariQueue(queue, () => throw StateError('db gone'));
      final failed = queue;
      queue = runAfterMinotariQueue(queue, () => ran.add('later'));

      await expectLater(failed, completes);
      await queue;
      expect(ran, ['later']);
    });

    test('runs work in order', () async {
      final ran = <int>[];
      var queue = Future<void>.value();
      queue = runAfterMinotariQueue(queue, () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        ran.add(1);
      });
      queue = runAfterMinotariQueue(queue, () => ran.add(2));

      await queue;
      expect(ran, [1, 2]);
    });
  });

  group('minotariKeysRecoveryText', () {
    test('a spendable import lists both private keys', () {
      final text = minotariKeysRecoveryText(
          WalletKeysData(scanSecret: 'aa', privateKey: 'bb', spendPubkey: 'cc'));

      expect(text, 'view_key: aa\nspend_key: bb');
    });

    test('a watch-only import lists the view key and spend public key', () {
      final text = minotariKeysRecoveryText(WalletKeysData(scanSecret: 'aa', spendPubkey: 'cc'));

      expect(text, 'view_key: aa\nspend_pubkey: cc');
    });
  });

  group('minotariSafeStartHeight', () {
    // (offline estimate, height a mainnet node reported) on 2026-01-01 and 2026-09-01: the
    // estimate leads by about 2,000 and 12,240 blocks.
    const samples = [(172622, 170622), (347579, 335339)];

    test('starts at or before the real block, with at least twice the lead to spare', () {
      for (final (estimate, real) in samples) {
        final lead = estimate - real;
        expect(minotariSafeStartHeight(estimate), lessThanOrEqualTo(estimate - 2 * lead));
      }
    });

    test('never goes below zero', () {
      expect(minotariSafeStartHeight(0), 0);
      expect(minotariSafeStartHeight(500), 0);
    });
  });

  group('minotariNodeUrl', () {
    Node node({required bool ssl}) =>
        Node(uri: 'rpc.tari.com', type: WalletType.minotari, useSSL: ssl);

    test('an SSL node gives its https URL', () {
      expect(minotariNodeUrl(node(ssl: true), torOn: false), 'https://rpc.tari.com');
    });

    test('with Tor turned on but not (yet, or ever) running nothing is sent', () {
      addTearDown(() => CakeTor.requested = false);
      CakeTor.requested = true;

      expect(CakeTor.instance?.started, isNot(true));
      expect(() => minotariNodeUrl(node(ssl: true), torOn: CakeTor.requestedOrStarted),
          throwsA(isA<TorUnsupportedException>()));
    });

    test('with Tor running nothing is sent', () {
      expect(() => minotariNodeUrl(node(ssl: true), torOn: true),
          throwsA(isA<TorUnsupportedException>()));
    });

    test('a non-SSL node is refused', () {
      expect(() => minotariNodeUrl(node(ssl: false), torOn: false), throwsException);
    });

    test('a node behind a SOCKS proxy is refused (cw would bypass it)', () {
      final proxied = node(ssl: true)..socksProxyAddress = '127.0.0.1:9050';
      expect(() => minotariNodeUrl(proxied, torOn: false), throwsException);
    });

    test('no node is refused', () {
      expect(() => minotariNodeUrl(null, torOn: false), throwsException);
    });
  });

  group('minotariThenRestore', () {
    test('restores after a failed action and keeps its error', () async {
      var restored = false;

      await expectLater(
        minotariThenRestore<String>(
          () async => throw StateError('not stalled'),
          () async => restored = true,
        ),
        throwsA(isA<StateError>()),
      );
      expect(restored, isTrue);
    });

    test('a failed restore keeps the action result', () async {
      final result = await minotariThenRestore<String>(
        () async => 'abandoned',
        () async => throw StateError('reload failed'),
      );

      expect(result, 'abandoned');
    });
  });

  group('quoteMinotariSend', () {
    const priorities = {
      MinotariTransactionPriority.slow: (FeePriority.slow, 2),
      MinotariTransactionPriority.medium: (FeePriority.medium, 7),
      MinotariTransactionPriority.fast: (FeePriority.fast, 30),
    };
    Future<FeeEstimate> estimate(FeePriority priority) async => FeeEstimate(
          estimatedFee: BigInt.from(priority.index * 1000 + 100),
          totalAmountRequired: BigInt.zero,
          feePerGram: BigInt.from(priorities.values.firstWhere((p) => p.$1 == priority).$2),
          inputCount: BigInt.one,
        );
    Future<BigInt> feePerGram(FeePriority priority) async =>
        BigInt.from(priorities.values.firstWhere((p) => p.$1 == priority).$2);

    test('a send is built at the rate of the quote for the chosen priority', () async {
      for (final MapEntry(key: priority, value: (feePriority, rate)) in priorities.entries) {
        final quote = await quoteMinotariSend(
          priority: priority,
          sendAll: false,
          amount: 5000,
          estimate: estimate,
          feePerGram: (_) => fail('a normal send takes the rate from its quote'),
          estimateSendAll: (_) => fail('not a send-all'),
        );
        expect(quote.feePerGram, BigInt.from(rate), reason: '$priority');
        expect(quote.fee, feePriority.index * 1000 + 100, reason: '$priority');
        expect(quote.amount, 5000);
      }
    });

    test('a send-all is quoted and built at the chosen priority\'s rate', () async {
      for (final MapEntry(key: priority, value: (_, rate)) in priorities.entries) {
        BigInt? quotedAt;
        final quote = await quoteMinotariSend(
          priority: priority,
          sendAll: true,
          amount: 0,
          estimate: (_) => fail('a send-all is not quoted by amount'),
          feePerGram: feePerGram,
          estimateSendAll: (feePerGram) async {
            quotedAt = feePerGram;
            return SendAllFeeEstimate(
              fee: feePerGram * BigInt.from(100),
              amountAfterFee: BigInt.from(900000),
              inputCount: BigInt.two,
              skippedDust: BigInt.zero,
              skippedOverCap: BigInt.zero,
            );
          },
        );
        expect(quotedAt, BigInt.from(rate), reason: '$priority');
        expect(quote.feePerGram, BigInt.from(rate), reason: '$priority');
        expect(quote.fee, rate * 100);
        expect(quote.amount, 900000);
      }
    });

    test('no priority quotes at Medium', () async {
      final quote = await quoteMinotariSend(
        priority: null,
        sendAll: false,
        amount: 1,
        estimate: estimate,
        feePerGram: feePerGram,
        estimateSendAll: (_) => fail('not a send-all'),
      );
      expect(quote.feePerGram, BigInt.from(7));
    });
  });
  group('minotariBroadcastResult', () {
    SendTransactionEvent event(TransactionStage stage, {SendResultDto? result}) =>
        SendTransactionEvent(stage: stage, details: stage.name, result: result);

    final result = SendResultDto(
      transaction: DisplayedTransactionDto(
        id: '42',
        direction: DisplayedTransactionDirection.outgoing,
        source: DisplayedTransactionSource.oneSided,
        status: DisplayedTransactionStatus.pending,
        amount: BigInt.from(1000),
        amountDisplay: '0.001 XTM',
        blockchain: BlockchainInfoDto(
          blockHeight: BigInt.zero,
          timestamp: '',
          confirmations: BigInt.zero,
        ),
        payrefs: const [],
      ),
      acceptedByNode: false,
      nodeReason: 'mempool full',
    );

    test('is the final Broadcasted event\'s result, accepted or not', () async {
      expect(
        await minotariBroadcastResult(Stream.fromIterable([
          event(TransactionStage.initializing),
          event(TransactionStage.broadcasting),
          event(TransactionStage.broadcasted, result: result),
        ])),
        result,
      );
    });

    test('a stream without a broadcast is a failure', () async {
      await expectLater(
        minotariBroadcastResult(Stream.fromIterable([
          event(TransactionStage.initializing),
          event(TransactionStage.broadcasting),
        ])),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('MinotariSendNotes', () {
    late Directory dir;
    late String path;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('minotari_notes');
      path = '${dir.path}/wallet$minotariSendNotesSuffix';
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('a missing or unreadable file is no notes', () async {
      expect((await MinotariSendNotes.load(path)).abandoned, isEmpty);
      File(path).writeAsStringSync('not json');
      final notes = await MinotariSendNotes.load(path);
      expect([notes.notAccepted, notes.abandoned, notes.alerted], everyElement(isEmpty));
    });

    test('notes survive a reload', () async {
      final notes = await MinotariSendNotes.load(path);
      await notes.update((notes) {
        notes.notAccepted['1'] = 'mempool full';
        notes.abandoned.add('2');
        notes.alerted.add('3');
      });

      final reloaded = await MinotariSendNotes.load(path);
      expect(reloaded.notAccepted, {'1': 'mempool full'});
      expect(reloaded.abandoned, {'2'});
      expect(reloaded.alerted, {'3'});
      expect(File('$path.tmp').existsSync(), isFalse);
    });

    test('an update keeps what another engine wrote meanwhile', () async {
      final foreground = await MinotariSendNotes.load(path);
      final background = await MinotariSendNotes.load(path);
      await background.update((notes) => notes.abandoned.add('2'));

      await foreground.update((notes) => notes.alerted.add('3'));

      final reloaded = await MinotariSendNotes.load(path);
      expect(reloaded.abandoned, {'2'});
      expect(reloaded.alerted, {'3'});
    });

    test('a failed write still changes the notes in memory', () async {
      final notes = await MinotariSendNotes.load('${dir.path}/missing/wallet.sends.json');
      await notes.update((notes) => notes.abandoned.add('2'));
      expect(notes.abandoned, {'2'});
    });
  });

  group('addMinotariSendNotes', () {
    Map<String, dynamic> notesFor(
      String id,
      DisplayedTransactionStatus status, {
      Set<String> minedAfterAbandon = const {},
    }) {
      final notes = MinotariSendNotes('unused')
        ..notAccepted['1'] = 'mempool full'
        ..notAccepted['4'] = ''
        ..abandoned.add('2');
      final info = <String, dynamic>{};
      addMinotariSendNotes(
        info,
        id: id,
        status: status,
        notes: notes,
        minedAfterAbandon: minedAfterAbandon,
      );
      return info;
    }

    test('a send the node did not accept says so while it is pending', () {
      expect(notesFor('1', DisplayedTransactionStatus.pending),
          {'notAcceptedByNode': 'mempool full'});
      expect(notesFor('4', DisplayedTransactionStatus.pending), {'notAcceptedByNode': ''});
    });

    test('once cw sees it on chain (or gives it up) the warning no longer applies', () {
      for (final status in [
        DisplayedTransactionStatus.unconfirmed,
        DisplayedTransactionStatus.confirmed,
        DisplayedTransactionStatus.rejected,
      ]) {
        expect(notesFor('1', status), isEmpty, reason: '$status');
      }
    });

    test('marks abandoned sends and those mined after all', () {
      expect(notesFor('2', DisplayedTransactionStatus.rejected), {'abandoned': true});
      expect(
        notesFor('2', DisplayedTransactionStatus.confirmed, minedAfterAbandon: {'2'}),
        {'abandoned': true, 'minedAfterAbandon': true},
      );
      expect(notesFor('3', DisplayedTransactionStatus.confirmed), isEmpty);
    });
  });

  test('minotariMinedAfterAbandon keeps only the sends mined after all', () {
    AbandonWarningDto warning(String id, AbandonWarningKind kind) =>
        AbandonWarningDto(transactionId: id, kind: kind, eventId: 1);

    expect(
      minotariMinedAfterAbandon([
        warning('1', AbandonWarningKind.acceptedAfterAbandon),
        warning('2', AbandonWarningKind.minedAfterAbandon),
      ]),
      ['2'],
    );
  });

  group('MinotariFfi.sendDetails', () {
    final ffi = MinotariFfi(dataPath: 'unused', walletName: 'wallet');
    final recipients = [SendRecipient(address: 'addr', amount: BigInt.from(5))];

    test('pays an abandoned send again when given its id', () {
      final details = ffi.sendDetails(
        recipients: recipients,
        sendAll: false,
        baseNodeUrl: 'https://node',
        conflictsWithTransactionId: '42',
      );
      expect(details.conflictsWithTransactionId, '42');
      expect(details.walletName, 'wallet');
      expect(details.recipients, recipients);
    });

    test('a plain send conflicts with nothing', () {
      final details =
          ffi.sendDetails(recipients: recipients, sendAll: true, baseNodeUrl: 'https://node');
      expect(details.conflictsWithTransactionId, isNull);
      expect(details.sendAll, isTrue);
    });
  });
}
