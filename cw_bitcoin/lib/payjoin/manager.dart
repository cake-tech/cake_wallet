import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/payjoin/mailroom_manager.dart';
import 'package:cw_bitcoin/payjoin/payjoin_event_store.dart';
import 'package:cw_bitcoin/payjoin/payjoin_persister.dart';
import 'package:cw_bitcoin/payjoin/payjoin_receive_worker.dart';
import 'package:cw_bitcoin/payjoin/payjoin_send_worker.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/psbt/utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/amount/money.dart';
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
    final now = DateTime.now();

    for (final session in allSessions) {
      final expiresAt = session.expiresAt;
      if (expiresAt != null && now.isAfter(expiresAt)) {
        final id = session.isSenderSession ? session.pjUri : session.receiver;
        if (id == null) continue;
        writePayjoinLog(
            "Session($id) expired on resume (expired at ${session.expiresAt})");
        if (session.isSenderSession) {
          await _payjoinStorage.markSenderSessionUnrecoverable(
            id,
            'Session expired before completing',
          );
        } else {
          await _payjoinStorage.markReceiverSessionUnrecoverable(
            id,
            'Session expired before completing',
          );
        }
        continue;
      }

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
        final stored = _payjoinStorage.getReceiverSession(sessionId);
        final alreadySuccess = stored?.status == PayjoinSessionStatus.success.name;
        if (!alreadySuccess) {
          await _payjoinStorage.markReceiverSessionUnrecoverable(
            sessionId,
            'Session closed without producing a transaction',
          );
        }
        return;
      }

      if (state is pj.ReceiverPendingFallbackReceiveSession) {
        try {
          final rawTxBytes = state.inner.fallbackTx();
          if (rawTxBytes.isNotEmpty) {
            final hex = BytesUtils.toHexString(rawTxBytes);
            await _payjoinStorage.storeReceiverPsbt(
              sessionId,
              'RAW:$hex',
            );
          }
        } catch (e) {
          writePayjoinLog(
            '[WARNING] Receiver($sessionId) fallbackTx extraction: $e',
          );
        }
        await _payjoinStorage.markReceiverSessionUnrecoverable(
          sessionId,
          'Session cancelled; broadcast the fallback transaction',
        );
        return;
      }

      if (state is pj.HasReplyableExceptionReceiveSession) {
        try {
          final cancelTransition = state.inner.cancel();
          final pending = cancelTransition.save(persister: persister);
          if (pending != null) {
            final rawTxBytes = pending.fallbackTx();
            if (rawTxBytes.isNotEmpty) {
              final hex = BytesUtils.toHexString(rawTxBytes);
              await _payjoinStorage.storeReceiverPsbt(
                sessionId,
                'RAW:$hex',
              );
            }
            pending.close();
          }
        } catch (e) {
          writePayjoinLog(
            '[WARNING] Receiver($sessionId) cancel->fallback: $e',
          );
        }
        await _payjoinStorage.markReceiverSessionUnrecoverable(
          sessionId,
          'Unrecoverable error',
        );
        return;
      }

      // Non-terminal states — update status and spawn worker to continue
      // polling from the replayed event log.
      if (state is pj.InitializedReceiveSession) {
        await _payjoinStorage.markReceiverSessionWaiting(sessionId);
      } else {
        await _payjoinStorage.markReceiverSessionInProgress(sessionId);
        writePayjoinLog("Receiver($sessionId) resume: ${state.runtimeType}");
      }
      _maybeResumeReceiverWorker(sessionId);
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

      if (state is pj.ClosedSendSession) {
        final outcome = state.inner;
        if (outcome.isAborted()) {
          await _payjoinStorage.markSenderSessionUnrecoverable(
            pjUri,
            'Session aborted without producing a transaction',
          );
          return;
        }

        // Closed(Success): protocol completed. If already marked success
        // in storage, nothing to do. Otherwise the prior run got the
        // proposal PSBT but couldn't broadcast (wallet was closed) — try
        // broadcast now with the fresh electrum client.
        final stored = _payjoinStorage.getSenderSession(pjUri);
        if (stored?.status == PayjoinSessionStatus.success.name) {
          return;
        }
        final psbt = outcome.successPsbtBase64();
        if (psbt == null) {
          writePayjoinLog(
              "Sender($pjUri) Closed(Success) but no PSBT available");
          await _payjoinStorage.markSenderSessionUnrecoverable(
            pjUri,
            'Could not retrieve finalized PSBT from completed session',
          );
          return;
        }
        try {
          // The FFI's Closed(Success) PSBT strips the sender's witness data
          // (final_script_witness = null) while keeping the receiver's. Re-sign
          // to populate the sender's signature before broadcasting.
          final utxos = _wallet.getUtxoWithPrivateKeys();
          final finalizedPsbt = await _wallet.signPsbt(psbt, utxos);
          final txId = getTxIdFromPsbtV0(finalizedPsbt);
          await _wallet.commitPsbt(finalizedPsbt);
          await _payjoinStorage.markSenderSessionComplete(pjUri, txId);
          writePayjoinLog(
              "Sender($pjUri) retry broadcast succeeded: $txId");
        } catch (e) {
          writePayjoinLog(
              "[WARNING] Sender($pjUri) retry broadcast failed: $e");
          // Keep inProgress — will retry on next resume
        }
        return;
      }

      if (state is pj.SenderPendingFallbackSendSession) {
        await _payjoinStorage.markSenderSessionUnrecoverable(
          pjUri,
          'Session cancelled; broadcast the fallback transaction',
        );
        return;
      }

      // Non-terminal states — update status and spawn worker to continue
      // polling from the replayed event log.
      if (state is pj.WithReplyKeySendSession) {
        await _payjoinStorage.markSenderSessionWaiting(pjUri);
      } else if (state is pj.PollingForProposalSendSession) {
        await _payjoinStorage.markSenderSessionInProgress(pjUri);
      } else {
        writePayjoinLog("Sender($pjUri) resume: ${state.runtimeType}");
      }
      _maybeResumeSenderWorker(pjUri);
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
      networkFeesSatPerVb: networkFeesSatPerVb,
      recipientAddress: recipientAddress,
    );

    // Store sender-side expiry parsed from BIP21.
    final expiryParam = Uri.tryParse(pjUrl)?.queryParameters['pj_expiry'];
    if (expiryParam != null) {
      final expirySecs = int.tryParse(expiryParam);
      if (expirySecs != null) {
        final session = _payjoinStorage.getSessionByEndpoint(pjUri);
        if (session != null) {
          session.expiresAt = DateTime.fromMillisecondsSinceEpoch(expirySecs * 1000);
          await session.save();
        }
      }
    }

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
      writePayjoinLog("Sender($pjUri) proposedPSBT len=${proposalPsbt.length}");

      final utxos = _wallet.getUtxoWithPrivateKeys();
      writePayjoinLog(
          "Sender($pjUri) utxos=${utxos.length}; types=${utxos.map((u) => u.utxo.scriptType.value).toList()}");
      final finalizedPsbt = await _wallet.signPsbt(proposalPsbt, utxos);

      final txId = getTxIdFromPsbtV0(finalizedPsbt);
      writePayjoinLog("Sender($pjUri) expected: $txId");

      await _wallet.commitPsbt(finalizedPsbt);
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
      _runningSenders.remove(pjUri)?.dispose();
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

  /// Returns true when [pjUriString]'s `pj=` endpoint resolves to a
  /// receiver session owned by THIS wallet. Used by the send flow to
  /// silently downgrade a self-addressed payjoin URI to a regular self-send
  /// (the receiver would reject such a proposal at BIP78's
  /// `checkInputsNotOwned` anyway). Returns false for malformed URIs or
  /// endpoints that don't match any local receiver session.
  bool isSelfSendPayjoinUri(String? pjUriString) {
    if (pjUriString == null || pjUriString.isEmpty) return false;
    String endpoint;
    try {
      final pjUri = pj.Uri.parse(uri: pjUriString).checkPjSupported();
      endpoint = pjUri.pjEndpoint();
    } catch (_) {
      return false;
    }
    final ownReceiver = _payjoinStorage.getReceiverSession(endpoint);
    return ownReceiver != null && ownReceiver.walletId == _wallet.id;
  }

  Future<String> initReceiver(String address,
      [bool isTestnet = false, int retryCount = 0, bool shouldSaveRecipientAddress = false]) async {
    // Hard guard: refuse to create or persist a receiver session when the
    // wallet has no spendable UTXOs. Without a receiver input the proposal
    // can never be finalized and the session would be marked unrecoverable
    // after wasting directory/OHTTP round-trips.
    if (!_wallet.isPayjoinAvailable) {
      writePayjoinLog('Refusing to create payjoin receiver session: no spendable UTXOs available');
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

        final pjUri = initialized.pjUri();
        final pjEndpoint = pjUri.pjEndpoint();

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

        // Store session expiry parsed from BIP21.
        final uriString = pjUri.asString();
        final expiryParam = Uri.tryParse(uriString)?.queryParameters['pj_expiry'];
        if (expiryParam != null) {
          final expirySecs = int.tryParse(expiryParam);
          if (expirySecs != null) {
            final session = _payjoinStorage.getReceiverSession(pjEndpoint);
            if (session != null) {
              session.expiresAt = DateTime.fromMillisecondsSinceEpoch(expirySecs * 1000);
              await session.save();
            }
          }
        }

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
          // Sender's original PSBT is now in the event log.  Extract the
          // receiver's output amount so the dashboard displays a real value
          // instead of 0 during the processing window.
          _trySetReceiverAmountFromEvents(pjEndpoint);
        },
      );

      _runningReceivers[pjEndpoint] = worker;

      try {
        final psbt = await worker.run(address, directory, ohttpKeys);
        writePayjoinLog("Receiver($pjEndpoint) proposalSent len=${psbt.length}");
        // worker.run() returned — the proposal was posted to the directory.
        // Metadata extraction is best-effort; failures here don't affect the
        // protocol state (the sender can still pick up and broadcast).
        String txId = '';
        String netAmount = '0';
        try {
          txId = getTxIdFromPsbtV0(psbt);
        } catch (e) {
          writePayjoinLog('[WARNING] Receiver($pjEndpoint) txId extraction: $e');
        }
        try {
          netAmount = getReceiverNetAmountFromPsbt(psbt, _wallet);
        } catch (e) {
          writePayjoinLog('[WARNING] Receiver($pjEndpoint) netAmount calc: $e');
        }
        // Store the proposal PSBT so the user can fallback-broadcast if the
        // sender drops off after the proposal is posted.
        final session = _payjoinStorage.getReceiverSession(pjEndpoint);
        if (session != null) {
          session.originalPsbt = psbt;
          await session.save();
        }

        _payjoinStorage.markReceiverSessionComplete(
          pjEndpoint,
          txId,
          netAmount,
        );
      } finally {
        _runningReceivers.remove(pjEndpoint)?.dispose();
      }
    } catch (e) {
      writePayjoinLog("[ERROR] Receiver($pjEndpoint) $e");
      // Don't mark unrecoverable: the directory session is independent of the
      // local worker.  A transient error here (FFI panic, metadata parse
      // failure) shouldn't prevent the session from being visible in the UI or
      // resumable on the next launch.  The resumeSessions() expiry check
      // cleans up sessions that are genuinely dead.
    }
  }

  void cancelReceiver(String pjEndpoint) {
    final worker = _runningReceivers.remove(pjEndpoint);
    worker?.cancel();
    worker?.dispose();
    _payjoinStorage.markReceiverSessionUnrecoverable(pjEndpoint, 'Cancelled');
    writePayjoinLog("Receiver($pjEndpoint) Cancelled");
  }

  /// Re-spawns a receiver worker from its persisted event log so polling and
  /// proposal processing continue after a wallet switch / app restart.
  ///
  /// Idempotent: skips when a worker is already running for [endpoint], or
  /// when there are no events to replay. The replay path inside the worker
  /// ignores the `address`/`directory`/`ohttpKeys` args (those are bound to
  /// the replayed FFI state), so callers can pass placeholders.
  void _maybeResumeReceiverWorker(String endpoint) {
    if (_runningReceivers.containsKey(endpoint)) return;

    final session = _payjoinStorage.getReceiverSession(endpoint);
    if (session == null) return;

    final persister = PayjoinReceiverPersister(_eventStore.box, endpoint);
    if (persister.load().isEmpty) return;

    final worker = PayjoinReceiverWorker(
      mailroomManager: _mailroomManager,
      utxos: _wallet.getUtxoWithPrivateKeys(),
      isMineChecker: (scriptBytes) {
        final script = Script.fromRaw(byteData: scriptBytes);
        return _wallet.isMine(script);
      },
      persister: persister,
      onProposalReceived: () {
        _payjoinStorage.markReceiverSessionInProgress(endpoint);
        _trySetReceiverAmountFromEvents(endpoint);
      },
    );
    _runningReceivers[endpoint] = worker;
    writePayjoinLog("Receiver($endpoint) resuming worker from event log");

    // Drive in the background; mirrors spawnReceiver's post-run handling.
    unawaited(_driveReceiverToCompletion(worker, endpoint));
  }

  Future<void> _driveReceiverToCompletion(
    PayjoinReceiverWorker worker,
    String endpoint,
  ) async {
    try {
      final psbt = await worker.resume();
      writePayjoinLog("Receiver($endpoint) proposalSent len=${psbt.length}");

      String txId = '';
      String netAmount = '0';
      try {
        txId = getTxIdFromPsbtV0(psbt);
      } catch (e) {
        writePayjoinLog('[WARNING] Receiver($endpoint) txId extraction: $e');
      }
      try {
        netAmount = getReceiverNetAmountFromPsbt(psbt, _wallet);
      } catch (e) {
        writePayjoinLog('[WARNING] Receiver($endpoint) netAmount calc: $e');
      }
      final session = _payjoinStorage.getReceiverSession(endpoint);
      if (session != null) {
        session.originalPsbt = psbt;
        await session.save();
      }
      _payjoinStorage.markReceiverSessionComplete(endpoint, txId, netAmount);
    } catch (e) {
      writePayjoinLog("[ERROR] Receiver($endpoint) $e");
      // Don't mark unrecoverable: same rationale as spawnReceiver — a
      // transient error here shouldn't prevent the next wallet-switch
      // resume from retrying.
    } finally {
      _runningReceivers.remove(endpoint)?.dispose();
    }
  }

  /// Re-spawns a sender worker from its persisted event log so the polling
  /// loop continues after a wallet switch / app restart.
  ///
  /// Idempotent: skips when a worker is already running for [endpoint], or
  /// when the session has no original PSBT / no events to replay.
  void _maybeResumeSenderWorker(String endpoint) {
    if (_runningSenders.containsKey(endpoint)) return;

    final session = _payjoinStorage.getSenderSession(endpoint);
    if (session == null) return;
    final originalPsbt = session.originalPsbt;
    if (originalPsbt == null || originalPsbt.isEmpty) return;

    final persister = PayjoinSenderPersister(_eventStore.box, endpoint);
    if (persister.load().isEmpty) return;

    final worker = PayjoinSenderWorker(
      mailroomManager: _mailroomManager,
      persister: persister,
    );
    _runningSenders[endpoint] = worker;
    writePayjoinLog("Sender($endpoint) resuming worker from event log");

    // Drive in the background; replay path ignores the original PSBT.
    unawaited(_driveSenderToCompletion(worker, endpoint));
  }

  Future<void> _driveSenderToCompletion(
    PayjoinSenderWorker worker,
    String endpoint,
  ) async {
    try {
      final proposalPsbt = await worker.resume();
      writePayjoinLog("Sender($endpoint) proposedPSBT len=${proposalPsbt.length}");

      final utxos = _wallet.getUtxoWithPrivateKeys();
      writePayjoinLog(
          "Sender($endpoint) utxos=${utxos.length}; types=${utxos.map((u) => u.utxo.scriptType.value).toList()}");
      final finalizedPsbt = await _wallet.signPsbt(proposalPsbt, utxos);

      final txId = getTxIdFromPsbtV0(finalizedPsbt);
      writePayjoinLog("Sender($endpoint) expected: $txId");

      await _wallet.commitPsbt(finalizedPsbt);
      await _payjoinStorage.markSenderSessionComplete(endpoint, txId);
    } on PayjoinSenderCancelledException {
      writePayjoinLog("Sender($endpoint) Cancelled by user");
      await _payjoinStorage.markSenderSessionUnrecoverable(endpoint, 'Cancelled');
    } on PayjoinSenderFallbackAvailableException catch (e) {
      writePayjoinLog(
          "Sender($endpoint) fallback required by replayed state (len=${e.fallbackTx.length})");
      await _payjoinStorage.markSenderSessionUnrecoverable(
        endpoint,
        'Session cancelled; broadcast the fallback transaction',
      );
    } catch (e, s) {
      writePayjoinLog("[ERROR] Sender($endpoint) $e\n$s");
      await _payjoinStorage.markSenderSessionUnrecoverable(endpoint, e.toString());
    } finally {
      _runningSenders.remove(endpoint)?.dispose();
    }
  }

  /// Parses the last [RetrievedOriginalPayload] event from the receiver event
  /// log and sums the output amounts that belong to this wallet, then writes
  /// the total into [PayjoinSession.rawAmount].
  void _trySetReceiverAmountFromEvents(String sessionId) {
    try {
      final events = _eventStore.loadReceiver(sessionId);
      for (final event in events) {
        final map = jsonDecode(event);
        final payload = map['RetrievedOriginalPayload'];
        if (payload == null) continue;
        final psbt = payload['original']['psbt'];
        if (psbt == null) continue;
        final outputs = psbt['unsigned_tx']['output'] as List?;
        if (outputs == null || outputs.isEmpty) continue;

        int total = 0;
        for (final output in outputs) {
          final scriptPubkey = output['script_pubkey'] as String?;
          if (scriptPubkey == null || scriptPubkey.isEmpty) continue;
          final script = Script.fromRaw(
            byteData: BytesUtils.fromHexString(scriptPubkey),
          );
          if (_wallet.isMine(script)) {
            total += (output['value'] as num).toInt();
          }
        }

        if (total > 0) {
          final session = _payjoinStorage.getReceiverSession(sessionId);
          if (session != null && (session.rawAmount == null || session.rawAmount == '0')) {
            session.rawAmount = total.toString();
            session.save();
            writePayjoinLog(
              "Receiver($sessionId) amount=$total sats "
              '(from RetrievedOriginalPayload)',
            );
          }
        }
        return; // Only process the first (earliest) match.
      }
    } catch (e) {
      writePayjoinLog(
        '[WARNING] Receiver($sessionId) amount-from-events: $e',
      );
    }
  }

  /// `cancel()` → `PendingFallback` → `fallbackTx()`, stores the raw
  /// transaction hex for later fallback broadcast.
  Future<void> _tryExtractReceiverFallback(String sessionId) async {
    try {
      final events = _eventStore.loadReceiver(sessionId);
      if (events.isEmpty) return;

      final persister = PayjoinReceiverPersister(_eventStore.box, sessionId);
      final replayResult = pj.replayReceiverEventLog(persister: persister);
      final state = replayResult.state();
      replayResult.dispose();

      // States that have progressed past UncheckedOriginalPayload have
      // fallback_tx available.  Earlier states (Initialized,
      // UncheckedOriginalPayload) do NOT — skip without persisting.
      final pending = _cancelToPendingFallback(state, persister);
      if (pending == null) return;

      try {
        final rawTxBytes = pending.fallbackTx();
        if (rawTxBytes.isNotEmpty) {
          await _payjoinStorage.storeReceiverPsbt(
            sessionId,
            'RAW:${BytesUtils.toHexString(rawTxBytes)}',
          );
        }
      } finally {
        pending.close();
      }
    } catch (e) {
      writePayjoinLog(
        '[WARNING] Receiver($sessionId) fallback extraction: $e',
      );
    }
  }

  /// Calls `cancel()` on the inner FFI state when possible and returns the
  /// resulting [pj.ReceiverPendingFallback], or `null` if the state doesn't
  /// support it (terminal / too-early states).
  pj.ReceiverPendingFallback? _cancelToPendingFallback(
    pj.ReceiveSession state,
    PayjoinReceiverPersister persister,
  ) {
    // States that DON'T have a fallback tx (per the Rust lib).
    if (state is pj.InitializedReceiveSession) return null;
    if (state is pj.UncheckedOriginalPayloadReceiveSession) return null;
    if (state is pj.ClosedReceiveSession) return null;

    // HasReplyableException — cancel() returns CancelTransition.
    if (state is pj.HasReplyableExceptionReceiveSession) {
      final transition = state.inner.cancel();
      return transition.save(persister: persister);
    }

    // Already in PendingFallback — just extract the inner fallback.
    if (state is pj.ReceiverPendingFallbackReceiveSession) return state.inner;

    // All remaining intermediate states expose cancel() on their inner type.
    // Dispatch by type to reach the inner FFI object.
    pj.ReceiverPendingFallback? pending;
    void saveCancel(pj.CancelTransition t) {
      pending = t.save(persister: persister);
    }

    if (state is pj.MaybeInputsOwnedReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.MaybeInputsSeenReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.OutputsUnknownReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.WantsOutputsReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.WantsInputsReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.WantsFeeRangeReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.ProvisionalProposalReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.PayjoinProposalReceiveSession) {
      saveCancel(state.inner.cancel());
    } else if (state is pj.MonitorReceiveSession) {
      saveCancel(state.inner.cancel());
    }

    return pending;
  }

  void cancelAllReceivers() {
    for (final worker in _runningReceivers.values) {
      worker.cancel();
      worker.dispose();
    }
    _runningReceivers.clear();
  }

  void cancelSender(String pjUri) {
    final worker = _runningSenders.remove(pjUri);
    worker?.cancel();
    worker?.dispose();
    writePayjoinLog("Sender($pjUri) Cancelled via cancelSender");
  }

  Future<void> fallbackBroadcast(String endpoint) async {
    final session = _payjoinStorage.getSessionByEndpoint(endpoint);
    final data = session?.originalPsbt;
    if (data == null || data.isEmpty) {
      writePayjoinLog("Fallback($endpoint) no stored PSBT");
      throw Exception('No fallback PSBT available');
    }

    final isSender = session!.isSenderSession;

    if (isSender) {
      await _payjoinStorage.markSenderSessionFallback(endpoint);
      cancelSender(endpoint);
    } else {
      cancelReceiver(endpoint);
    }

    try {
      if (data.startsWith('RAW:')) {
        // Fallback from PendingFallback — data is a hex-encoded raw Bitcoin
        // transaction (fully signed, no PSBT wrapping).
        final rawTxHex = data.substring(4);
        writePayjoinLog("Fallback($endpoint) broadcasting raw tx ($rawTxHex)");
        final btcTx = BtcTransaction.fromRaw(rawTxHex);
        final txId = btcTx.txId();

        // Compute receiver's total from wallet-matching outputs.
        String amount = '0';
        if (!isSender) {
          int total = 0;
          for (final output in btcTx.outputs) {
            if (_wallet.isMine(output.scriptPubKey)) {
              total += output.amount.toInt();
            }
          }
          amount = total.toString();
        }

        await PendingBitcoinTransaction(
          btcTx,
          _wallet.type,
          electrumClient: _wallet.electrumClient,
          amount: Money.zero(_wallet.currency),
          fee: Money.zero(_wallet.currency),
          feeRate: '',
          network: _wallet.network,
          hasChange: true,
          isViewOnly: false,
        ).commit();
        if (isSender) {
          await _payjoinStorage.markSenderSessionComplete(
            endpoint,
            txId,
            usedFallback: true,
          );
        } else {
          await _payjoinStorage.markReceiverSessionComplete(
            endpoint,
            txId,
            amount,
            usedFallback: true,
          );
        }
        writePayjoinLog("Fallback($endpoint) broadcast tx $txId");
      } else {
        // Standard PSBT fallback (sender original PSBT or receiver proposal PSBT)
        writePayjoinLog("Fallback($endpoint) broadcasting PSBT");
        await _wallet.commitPsbt(data);
        final txId = getTxIdFromPsbtV0(data);
        if (isSender) {
          await _payjoinStorage.markSenderSessionComplete(
            endpoint,
            txId,
            usedFallback: true,
          );
        } else {
          final amount = getReceiverNetAmountFromPsbt(data, _wallet);
          await _payjoinStorage.markReceiverSessionComplete(
            endpoint,
            txId,
            amount,
            usedFallback: true,
          );
        }
        writePayjoinLog("Fallback($endpoint) broadcast tx $txId");
      }
    } catch (e) {
      writePayjoinLog("[ERROR] Fallback($endpoint) $e");
      rethrow;
    }
  }

  bool hasActiveReceiverSession(String walletId) =>
      _payjoinStorage.hasActiveReceiverSession(walletId);

  PayjoinSession? sessionForTxId(String txId) =>
      _payjoinStorage.getSessionByTxId(txId, walletId: _wallet.id);

  /// Looks up a payjoin session for [txId] in this wallet's storage. If no
  /// session has [txId] recorded yet (common when the receiver worker was
  /// killed before reaching `markReceiverSessionComplete` — e.g. mid
  /// wallet-switch), fall back to matching the tx's [outputAddresses] against
  /// receiver sessions' [PayjoinSession.recipientAddress]. A match
  /// retroactively associates the broadcast tx with the receiver session so
  /// the dashboard can render the correct (incoming) direction.
  PayjoinSession? sessionForTxIdWithBackfill(
    String txId,
    List<String> outputAddresses,
  ) {
    final direct = _payjoinStorage.getSessionByTxId(txId, walletId: _wallet.id);
    if (direct != null) return direct;
    if (outputAddresses.isEmpty) return null;

    final matched = _payjoinStorage.findReceiverSessionByRecipientAddress(
      _wallet.id,
      outputAddresses.toSet(),
    );
    if (matched == null || matched.receiver == null) return null;

    // Backfill: this broadcast IS the receiver's payjoin outcome.
    matched.status = PayjoinSessionStatus.success.name;
    matched.txId = txId;
    unawaited(matched.save());
    writePayjoinLog(
      "Receiver(${matched.receiver}) backfilled txId=$txId via output-address match",
    );
    return matched;
  }

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
    for (final worker in _runningSenders.values) {
      worker.cancel();
      worker.dispose();
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
