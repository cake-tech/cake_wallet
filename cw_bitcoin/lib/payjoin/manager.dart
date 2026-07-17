import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/payjoin/mailroom_manager.dart';
import 'package:cw_bitcoin/payjoin/payjoin_event_store.dart';
import 'package:cw_bitcoin/payjoin/payjoin_persister.dart';
import 'package:cw_bitcoin/payjoin/payjoin_receive_worker.dart';
import 'package:cw_bitcoin/payjoin/payjoin_send_worker.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/psbt/utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:payjoin/payjoin.dart' as pj;

class PayjoinManager {
  PayjoinManager(this._payjoinStorage, this._wallet, {MailroomManager? mailroomManager})
      : _mailroomManager = mailroomManager ??
            MailroomManager(
              relayUrls: const [
                'https://pj.bobspacebkk.com',
                'https://pj.benalleng.com',
                'https://ohttp.achow101.com',
              ],
              directoryUrls: const [
                'https://pj.benalleng.com',
                'https://payjo.in',
                'https://lets.payjo.in',
              ],
            );

  final PayjoinStorage _payjoinStorage;
  final BitcoinWalletBase _wallet;
  final MailroomManager _mailroomManager;

  void configureMailroom({
    required List<String> relays,
    required List<String> directories,
  }) {
    _mailroomManager.setConfig(relays: relays, directories: directories);
  }

  /// True when the wallet has at least one spendable, non-frozen UTXO.
  /// Required to contribute a receiver input to a payjoin proposal.
  bool get canCreateReceiver => _wallet.isPayjoinAvailable;
  final PayjoinEventStore _eventStore = PayjoinEventStore();
  final Map<String, PayjoinReceiverWorker> _runningReceivers = {};
  final Map<String, PayjoinSenderWorker> _runningSenders = {};

  var _logStreamController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logStreamController.stream;
  StreamSubscription<String>? _logSubscription;

  Future<void> initPayjoin() async {
    await Future.wait([initLogging(), _eventStore.ensureOpen()]);
  }

  Future<void> initLogging() async {
    _logSubscription?.cancel();
    _logStreamController = StreamController<String>.broadcast();

    try {
      final path = await pathForWalletDir(name: _wallet.name, type: _wallet.type);
      File("$path/payjoin.log")
          .create()
          .then(_subscribeToLogStream)
          .onError((e, s) async => printV("$e\n$s"));
    } catch (e) {
      printV(e);
    }
  }

  void _subscribeToLogStream(File logFile) {
    _logSubscription = logStream.listen((logEntry) {
      logFile.writeAsString("$logEntry\n", mode: FileMode.writeOnlyAppend);
    });
  }

  void writePayjoinLog(String message) {
    if (_logStreamController.isClosed) return;
    try {
      _logStreamController.add(message);
    } catch (_) {}
  }

  Future<void> resumeSessions() async {
    final allSessions = _payjoinStorage.readAllOpenSessions(_wallet.id);

    for (final session in allSessions) {
      if (session.isSenderSession) {
        await _resumeSenderSession(session.pjUri ?? '');
      } else {
        await _resumeReceiverSession(session.receiver ?? '');
      }
    }
  }

  Future<void> _resumeReceiverSession(String sessionId) async {
    if (sessionId.isEmpty) return;

    try {
      final events = _eventStore.loadReceiver(sessionId);
      if (events.isEmpty) {
        await _payjoinStorage.markReceiverSessionUnrecoverable(
          sessionId,
          'Stale session from previous version',
        );
        return;
      }

      final persister = PayjoinReceiverPersister(_eventStore.box, sessionId);
      final replayResult = pj.replayReceiverEventLog(persister: persister);
      final state = replayResult.state();
      replayResult.dispose();

      if (state is pj.ClosedReceiveSession) {
        // Closed receiver sessions are terminal. If the prior run already
        // recorded a txId (success) leave it untouched so the dashboard
        // history filter keeps showing it; only flag genuine aborts as
        // unrecoverable. We can't introspect ReceiverSessionOutcome
        // directly via the FFI, so fall back to the stored session status.
        final stored = _payjoinStorage.getReceiverSession(sessionId);
        final alreadySuccess =
            stored?.status == PayjoinSessionStatus.success.name;
        if (!alreadySuccess) {
          await _payjoinStorage.markReceiverSessionUnrecoverable(
            sessionId,
            'Session closed without producing a transaction',
          );
        }
      } else if (state is pj.HasReplyableExceptionReceiveSession) {
        await _payjoinStorage.markReceiverSessionUnrecoverable(
          sessionId,
          'Unrecoverable error',
        );
      } else if (state is pj.InitializedReceiveSession) {
        await _payjoinStorage.markReceiverSessionWaiting(sessionId);
      } else {
        await _payjoinStorage.markReceiverSessionInProgress(sessionId);
        writePayjoinLog("Receiver($sessionId) resume: ${state.runtimeType}");
      }
    } catch (e) {
      writePayjoinLog("[ERROR] Resume receiver($sessionId) $e");
    }
  }

  Future<void> _resumeSenderSession(String pjUri) async {
    try {
      final events = _eventStore.loadSender(pjUri);
      if (events.isEmpty) {
        return;
      }

      final persister = PayjoinSenderPersister(_eventStore.box, pjUri);
      final replayResult = pj.replaySenderEventLog(persister: persister);
      final state = replayResult.state();
      replayResult.dispose();

      // Mirror `process_sender_session` terminal-state handling from
      // payjoin-cli. `Closed(Success)` is the happy terminal state: the
      // session already has status=success+txId in storage from the prior
      // run, and the dashboard history filter shows it. Marking it
      // unrecoverable here would hide every successfully-sent payjoin on the
      // next app restart.
      if (state is pj.ClosedSendSession) {
        final outcome = state.inner;
        if (outcome.isAborted()) {
          await _payjoinStorage.markSenderSessionUnrecoverable(
            pjUri,
            'Session aborted without producing a transaction',
          );
        }
        // isSuccess(): leave the existing success status untouched.
      } else if (state is pj.SenderPendingFallbackSendSession) {
        await _payjoinStorage.markSenderSessionUnrecoverable(
          pjUri,
          'Session cancelled; broadcast the fallback transaction',
        );
      } else if (state is pj.WithReplyKeySendSession) {
        await _payjoinStorage.markSenderSessionWaiting(pjUri);
      } else if (state is pj.PollingForProposalSendSession) {
        await _payjoinStorage.markSenderSessionInProgress(pjUri);
      } else {
        writePayjoinLog("Sender($pjUri) resume: ${state.runtimeType}");
      }
    } catch (e) {
      writePayjoinLog("[ERROR] Resume sender($pjUri) $e");
    }
  }

  Future<void> spawnNewSender({
    required String pjUrl,
    required String originalPsbt,
    required BigInt amount,
    int networkFeesSatPerVb = 1,
    bool isTestnet = false,
    String? recipientAddress,
  }) async {
    final pjUri = Uri.parse(pjUrl).queryParameters['pj']!;
    await _payjoinStorage.insertSenderSession(
      pjUri,
      _wallet.id,
      amount,
      originalPsbt: originalPsbt,
      recipientAddress: recipientAddress,
    );

    final senderWorker = PayjoinSenderWorker(
      mailroomManager: _mailroomManager,
      persister: PayjoinSenderPersister(_eventStore.box, pjUri),
    );
    final minFeeRateSatPerKwu = networkFeesSatPerVb * 250;

    _runningSenders[pjUri] = senderWorker;

    try {
      writePayjoinLog("Sender($pjUri) Created");

      final proposalPsbt = await senderWorker.run(
        originalPsbt,
        pjUrl,
        minFeeRateSatPerKwu,
      );
      writePayjoinLog("Sender($pjUri) proposedPSBT len=${proposalPsbt.length}: $proposalPsbt");

      final utxos = _wallet.getUtxoWithPrivateKeys();
      writePayjoinLog(
          "Sender($pjUri) utxos=${utxos.length}; types=${utxos.map((u) => u.utxo.scriptType.value).toList()}");
      final finalizedPsbt = await _wallet.signPsbt(proposalPsbt, utxos);
      writePayjoinLog("Sender($pjUri) finalizedPsbt: $finalizedPsbt");

      final txId = getTxIdFromPsbtV0(finalizedPsbt);
      writePayjoinLog("Sender($pjUri) expected: $txId");

      _wallet.commitPsbt(finalizedPsbt);
      await _payjoinStorage.markSenderSessionComplete(pjUri, txId);
    } on PayjoinSenderCancelledException {
      writePayjoinLog("Sender($pjUri) Cancelled by user");
      await _payjoinStorage.markSenderSessionUnrecoverable(pjUri, 'Cancelled');
    } on PayjoinSenderFallbackAvailableException catch (e) {
      writePayjoinLog(
          "Sender($pjUri) fallback required by replayed state (len=${e.fallbackTx.length})");
      await _payjoinStorage.markSenderSessionUnrecoverable(
        pjUri,
        'Session cancelled; broadcast the fallback transaction',
      );
    } catch (e, s) {
      writePayjoinLog("[ERROR] Sender($pjUri) $e\n$s");
      await _payjoinStorage.markSenderSessionUnrecoverable(pjUri, e.toString());
    } finally {
      _runningSenders.remove(pjUri);
    }
  }

  Future<pj.OhttpKeys> _fetchOhttpKeys(String directory) async {
    return _mailroomManager.fetchOhttpKeysFromDirectory(directory);
  }

  Future<String> initSender(
    String pjUriString,
    String originalPsbt,
    int networkFeesSatPerVb,
  ) async {
    try {
      final pjUri = pj.Uri.parse(uri: pjUriString).checkPjSupported();
      return pjUri.pjEndpoint();
    } catch (e) {
      throw Exception('Error initializing Payjoin Sender: $e');
    }
  }

  Future<String> getUnusedReceiver(String address, [bool isTestnet = false]) async {
    final session = _payjoinStorage.getUnusedActiveReceiverSession(_wallet.id);
    if (session != null) return session.receiver ?? '';
    return initReceiver(address, isTestnet);
  }

  Future<String> initReceiver(String address,
      [bool isTestnet = false, int retryCount = 0, bool shouldSaveRecipientAddress = false]) async {
    // Hard guard: refuse to create or persist a receiver session when the
    // wallet has no spendable UTXOs. Without a receiver input the proposal
    // can never be finalized and the session would be marked unrecoverable
    // after wasting directory/OHTTP round-trips.
    if (!_wallet.isPayjoinAvailable) {
      writePayjoinLog(
          'Refusing to create payjoin receiver session: no spendable UTXOs available');
      throw StateError('Cannot start payjoin receiver: no spendable UTXOs available');
    }

    if (retryCount > 0) {
      writePayjoinLog("Retrying initReceiver ${retryCount + 1} attempt");
    }

    // Try directories in order with relay failover (like Rust reference impl)
    while (true) {
      String directory;
      try {
        directory = _mailroomManager.chooseDirectory();
      } on StateError {
        writePayjoinLog("No valid directories available");
        rethrow;
      }

      try {
        final ohttpKeys = await _fetchOhttpKeys(directory);

        final receiver = pj.ReceiverBuilder(
          address: address,
          directory: directory,
          ohttpKeys: ohttpKeys,
        );
        final initialTransition = receiver.build();

        final ephemeral = _EphemeralReceiverPersister();
        final initialized = initialTransition.save(persister: ephemeral);

        final pjEndpoint = initialized.pjUri().pjEndpoint();

        final durablePersister = PayjoinReceiverPersister(
          _eventStore.box,
          pjEndpoint,
        );
        for (final event in ephemeral.load()) {
          durablePersister.save(event);
        }

        await _payjoinStorage.insertReceiverSession(
          pjEndpoint,
          _wallet.id,
          recipientAddress: shouldSaveRecipientAddress ? address : null,
        );

        return pjEndpoint;
      } catch (e) {
        writePayjoinLog(e.toString());
        _mailroomManager.addFailedDirectory(directory);
        _mailroomManager.clearFailedRelays();
      }
    }
  }

  Future<void> spawnReceiver({
    required String pjEndpoint,
    required String address,
    bool isTestnet = false,
  }) async {
    try {
      final directory = _mailroomManager.chooseDirectory();
      final ohttpKeys = await _fetchOhttpKeys(directory);

      _payjoinStorage.markReceiverSessionWaiting(pjEndpoint);

      final persister = PayjoinReceiverPersister(
        _eventStore.box,
        pjEndpoint,
      );

      var utxos = _wallet.getUtxoWithPrivateKeys(confirmedOnly: true);
      if (utxos.isEmpty) {
        await _wallet.updateAllUnspents();
        utxos = _wallet.getUtxoWithPrivateKeys(confirmedOnly: true);
      }
      // Candidates arrive in wallet scan order (address, then age), which is
      // predictable; shuffle so the receiver's input choice can't mirror it.
      utxos.shuffle(Random.secure());
      final worker = PayjoinReceiverWorker(
        mailroomManager: _mailroomManager,
        utxos: utxos,
        isMineChecker: (scriptBytes) {
          final script = Script.fromRaw(byteData: scriptBytes);
          return _wallet.isMine(script);
        },
        persister: persister,
        onProposalReceived: () {
          _payjoinStorage.markReceiverSessionInProgress(pjEndpoint);
        },
      );

      _runningReceivers[pjEndpoint] = worker;

      try {
        final psbt = await worker.run(address, directory, ohttpKeys);
        writePayjoinLog("Receiver($pjEndpoint) proposalSent: $psbt");
        _payjoinStorage.markReceiverSessionComplete(
          pjEndpoint,
          getTxIdFromPsbtV0(psbt),
          getReceiverNetAmountFromPsbt(psbt, _wallet),
        );
      } finally {
        _runningReceivers.remove(pjEndpoint);
      }
    } catch (e) {
      writePayjoinLog("[ERROR] Receiver($pjEndpoint) $e");
      _payjoinStorage.markReceiverSessionUnrecoverable(
        pjEndpoint,
        e.toString(),
      );
    }
  }

  void cancelReceiver(String pjEndpoint) {
    _runningReceivers[pjEndpoint]?.cancel();
    _runningReceivers.remove(pjEndpoint);
    _payjoinStorage.markReceiverSessionUnrecoverable(pjEndpoint, 'Cancelled');
    writePayjoinLog("Receiver($pjEndpoint) Cancelled");
  }

  void cancelAllReceivers() {
    for (final entry in _runningReceivers.entries) {
      entry.value.cancel();
    }
    _runningReceivers.clear();
  }

  void cancelSender(String pjUri) {
    _runningSenders[pjUri]?.cancel();
    writePayjoinLog("Sender($pjUri) Cancelled via cancelSender");
  }

  Future<void> fallbackBroadcast(String pjUri) async {
    final session = _payjoinStorage.getSenderSession(pjUri);
    final psbt = session?.originalPsbt;
    if (psbt == null || psbt.isEmpty) {
      writePayjoinLog("Fallback($pjUri) no originalPsbt");
      throw Exception('No fallback PSBT available');
    }

    // Mark usedFallback before cancelSender so the sender catch handler
    // (markSenderSessionUnrecoverable) sees usedFallback=true and skips.
    await _payjoinStorage.markSenderSessionFallback(pjUri);
    cancelSender(pjUri);

    try {
      writePayjoinLog("Fallback($pjUri) broadcasting original PSBT");
      await _wallet.commitPsbt(psbt);
      final txId = getTxIdFromPsbtV0(psbt);
      await _payjoinStorage.markSenderSessionComplete(pjUri, txId, usedFallback: true);
      writePayjoinLog("Fallback($pjUri) broadcast tx $txId");
    } catch (e) {
      writePayjoinLog("[ERROR] Fallback($pjUri) $e");
      rethrow;
    }
  }

  bool hasActiveReceiverSession(String walletId) =>
      _payjoinStorage.hasActiveReceiverSession(walletId);

  PayjoinSession? sessionForTxId(String txId) =>
      _payjoinStorage.getSessionByTxId(txId);

  String generateExportData() {
    final buf = StringBuffer();
    buf.writeln('=== Payjoin Session Data ===');
    buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buf.writeln('');

    final allSessions = _payjoinStorage.readAllSessions(_wallet.id);
    for (final session in allSessions) {
      buf.writeln('--- Session ---');
      buf.writeln('Wallet: ${session.walletId}');
      buf.writeln(
          'Direction: ${session.isSenderSession ? "Sender (outgoing)" : "Receiver (incoming)"}');
      buf.writeln('Status: ${session.status}');
      buf.writeln('URI: ${session.pjUri ?? "-"}');
      buf.writeln('Receiver: ${session.receiver ?? "-"}');
      buf.writeln('Sender: ${session.sender ?? "-"}');
      buf.writeln('Amount: ${session.rawAmount ?? "-"}');
      buf.writeln('TxID: ${session.txId ?? "-"}');
      buf.writeln('Used Fallback: ${session.usedFallback}');
      buf.writeln('Error: ${session.error ?? "-"}');

      if (session.isSenderSession && session.pjUri != null) {
        final events = _eventStore.loadSender(session.pjUri!);
        if (events.isNotEmpty) {
          buf.writeln('Protocol Events (Sender):');
          for (final event in events) {
            buf.writeln('  $event');
          }
        }
      } else if (session.receiver != null) {
        final events = _eventStore.loadReceiver(session.receiver!);
        if (events.isNotEmpty) {
          buf.writeln('Protocol Events (Receiver):');
          for (final event in events) {
            buf.writeln('  $event');
          }
        }
      }
      buf.writeln('');
    }

    buf.writeln('=== End Payjoin Session Data ===');
    return buf.toString();
  }

  void cleanupSessions() {
    cancelAllReceivers();
    for (final entry in _runningSenders.entries) {
      entry.value.cancel();
    }
    _runningSenders.clear();
    _logSubscription?.cancel();
    _logStreamController.close();
  }
}

class _EphemeralReceiverPersister extends pj.JsonReceiverSessionPersister {
  final List<String> _events = [];

  @override
  void save(String event) => _events.add(event);

  @override
  List<String> load() => List.from(_events);

  @override
  void close() => _events.clear();
}
