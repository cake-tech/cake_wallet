import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_bitcoin/payjoin/payjoin_event_store.dart';
import 'package:cw_bitcoin/payjoin/payjoin_persister.dart';
import 'package:cw_bitcoin/payjoin/payjoin_receive_worker.dart';
import 'package:cw_bitcoin/payjoin/payjoin_send_worker.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/psbt/utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;
import 'package:payjoin/payjoin.dart' as pj;

class PayjoinManager {
  PayjoinManager(this._payjoinStorage, this._wallet);

  final PayjoinStorage _payjoinStorage;
  final BitcoinWalletBase _wallet;
  final http.Client _client = ProxyWrapper().getHttpIOClient();
  final PayjoinEventStore _eventStore = PayjoinEventStore();
  final Map<String, PayjoinReceiverWorker> _runningReceivers = {};
  final Map<String, PayjoinSenderWorker> _runningSenders = {};

  static const List<String> ohttpRelayUrls = [
    'https://pj.bobspacebkk.com',
    'https://ohttp.achow101.com',
    'https://ohttp.cakewallet.com',
  ];

  static String randomOhttpRelayUrl() =>
      ohttpRelayUrls[Random.secure().nextInt(ohttpRelayUrls.length)];

  static const payjoinDirectoryUrl = 'https://payjo.in';

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
        await _payjoinStorage.markReceiverSessionComplete(
          sessionId,
          '',
          '0',
        );
      } else if (state is pj.HasReplyableExceptionReceiveSession) {
        await _payjoinStorage.markReceiverSessionUnrecoverable(
          sessionId,
          'Unrecoverable error',
        );
      } else {
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

      if (state is pj.ClosedSendSession) {
        await _payjoinStorage.markSenderSessionComplete(pjUri, '');
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
  }) async {
    final pjUri = Uri.parse(pjUrl).queryParameters['pj']!;
    await _payjoinStorage.insertSenderSession(
      pjUri,
      _wallet.id,
      amount,
      originalPsbt: originalPsbt,
    );

    final senderWorker = PayjoinSenderWorker();
    final minFeeRateSatPerKwu = networkFeesSatPerVb * 250;
    final ohttpRelay = randomOhttpRelayUrl();

    _runningSenders[pjUri] = senderWorker;

    try {
      writePayjoinLog("Sender($pjUri) Created");

      final proposalPsbt = await senderWorker.run(
        originalPsbt,
        pjUrl,
        ohttpRelay,
        minFeeRateSatPerKwu,
      );
      writePayjoinLog("Sender($pjUri) proposedPSBT len=${proposalPsbt.length}: $proposalPsbt");

      final utxos = _wallet.getUtxoWithPrivateKeys();
      writePayjoinLog("Sender($pjUri) utxos=${utxos.length}; types=${utxos.map((u) => u.utxo.scriptType.value).toList()}");
      final finalizedPsbt = await _wallet.signPsbt(proposalPsbt, utxos);
      writePayjoinLog("Sender($pjUri) finalizedPsbt: $finalizedPsbt");

      final txId = getTxIdFromPsbtV0(finalizedPsbt);
      writePayjoinLog("Sender($pjUri) expected: $txId");

      _wallet.commitPsbt(finalizedPsbt);
      await _payjoinStorage.markSenderSessionComplete(pjUri, txId);
    } on PayjoinSenderCancelledException {
      writePayjoinLog("Sender($pjUri) Cancelled by user");
      await _payjoinStorage.markSenderSessionUnrecoverable(pjUri, 'Cancelled');
    } catch (e, s) {
      writePayjoinLog("[ERROR] Sender($pjUri) $e\n$s");
      await _payjoinStorage.markSenderSessionUnrecoverable(pjUri, e.toString());
    } finally {
      _runningSenders.remove(pjUri);
    }
  }

  Future<pj.OhttpKeys> _fetchOhttpKeys(
    String ohttpRelay,
    String directory,
  ) async {
    final keysUrl = Uri.parse('$directory/.well-known/ohttp-gateway');
    final resp = await _client.get(
      keysUrl,
      headers: {'Accept': 'application/ohttp-keys'},
    );
    return pj.OhttpKeys.decode(bytes: resp.bodyBytes);
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
    return initReceiver(address);
  }

  Future<String> initReceiver(String address, [bool isTestnet = false, int retryCount = 0]) async {
    if (retryCount > 0) {
      writePayjoinLog("Retrying initReceiver ${retryCount + 1} attempt");
    }

    try {
      final ohttpKeys = await _fetchOhttpKeys(
        randomOhttpRelayUrl(),
        payjoinDirectoryUrl,
      );

      final receiver = pj.ReceiverBuilder(
        address: address,
        directory: payjoinDirectoryUrl,
        ohttpKeys: ohttpKeys,
      );
      final initialTransition = receiver.build();

      // Build with ephemeral persister to extract pjEndpoint
      final ephemeral = _EphemeralReceiverPersister();
      final initialized = initialTransition.save(persister: ephemeral);

      final pjEndpoint = initialized.pjUri().pjEndpoint();

      // Save Initialized event to durable store so worker replays this session
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
      );

      return pjEndpoint;
    } catch (e) {
      writePayjoinLog(e.toString());
      if (e.toString().contains("error sending request for url") && retryCount < 5) {
        return initReceiver(address, isTestnet, ++retryCount);
      }
      rethrow;
    }
  }

  Future<void> spawnReceiver({
    required String pjEndpoint,
    required String address,
    bool isTestnet = false,
  }) async {
    try {
      final ohttpKeys = await _fetchOhttpKeys(
        randomOhttpRelayUrl(),
        payjoinDirectoryUrl,
      );

      _payjoinStorage.markReceiverSessionInProgress(pjEndpoint);

      final persister = PayjoinReceiverPersister(
        _eventStore.box,
        pjEndpoint,
      );

      final utxos = _wallet.getUtxoWithPrivateKeys();
      final worker = PayjoinReceiverWorker(
        ohttpRelay: randomOhttpRelayUrl(),
        utxos: utxos,
        isMineChecker: (scriptBytes) {
          final script = Script.fromRaw(byteData: scriptBytes);
          return _wallet.isMine(script);
        },
        persister: persister,
      );

      _runningReceivers[pjEndpoint] = worker;

      try {
        final psbt = await worker.run(address, payjoinDirectoryUrl, ohttpKeys);
        writePayjoinLog("Receiver($pjEndpoint) proposalSent: $psbt");
        _payjoinStorage.markReceiverSessionComplete(
          pjEndpoint,
          getTxIdFromPsbtV0(psbt),
          '0',
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

    cancelSender(pjUri);

    try {
      writePayjoinLog("Fallback($pjUri) broadcasting original PSBT");
      await _wallet.commitPsbt(psbt);
      final txId = getTxIdFromPsbtV0(psbt);
      await _payjoinStorage.markSenderSessionComplete(pjUri, txId);
      writePayjoinLog("Fallback($pjUri) broadcast tx $txId");
    } catch (e) {
      writePayjoinLog("[ERROR] Fallback($pjUri) $e");
      rethrow;
    }
  }

  bool hasActiveReceiverSession(String walletId) =>
      _payjoinStorage.hasActiveReceiverSession(walletId);

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
