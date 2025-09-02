part of "payjoin.dart";

class CWPayjoinManager extends PayjoinManager {
  CWPayjoinManager();

  PayjoinStorage? _payjoinStorage;
  BitcoinWalletBase? _wallet;
  final Map<String, PayjoinPollerSession> _activePollers = {};

  static const List<String> ohttpRelayUrls = [
    'https://pj.bobspacebkk.com',
    'https://ohttp.achow101.com',
    'https://ohttp.cakewallet.com',
  ];

  static String randomOhttpRelayUrl() =>
      ohttpRelayUrls[Random.secure().nextInt(ohttpRelayUrls.length)];

  static const payjoinDirectoryUrl = 'https://payjo.in';

  void init({required dynamic payjoinStorage, required BitcoinWalletBase wallet}) {
    if (payjoinStorage is! Box<PayjoinSession>) {
      throw ArgumentError('payjoinStorage must be an instance of PayjoinStorage');
    }

    _payjoinStorage = PayjoinStorage(payjoinStorage);
    _wallet = wallet;

    printV("Initializing Payjoin Manager for wallet ${_wallet!.id}");
  }

  Future<void> initPayjoin() => pj_config.PConfig.initializeApp();

  Future<void> resumeSessions() async {
    final allSessions = _payjoinStorage!.readAllOpenSessions(_wallet!.id);

    final spawnedSessions = allSessions.map((session) {
      try {
        if (session.isSenderSession) {
          printV("Resuming Payjoin Sender Session ${session.pjUri!}");
          return _spawnSender(
            sender: Sender.fromJson(json: session.sender!),
            pjUri: session.pjUri!,
          );
        }
        final receiver = Receiver.fromJson(json: session.receiver!);
        printV("Resuming Payjoin Receiver Session ${receiver.id()}");
        return spawnReceiver(receiver: receiver);
      } on pj_api.FfiSerdeJsonError catch (_) {
        _payjoinStorage!.markSenderSessionUnrecoverable(session.pjUri!, "Outdated Session");
      }
    }).nonNulls;

    printV("Resumed ${spawnedSessions.length} Payjoin Sessions");
    await Future.wait(spawnedSessions);
  }

  Future<Sender> initSender(
      String pjUriString, String originalPsbt, int networkFeesSatPerVb) async {
    try {
      final pjUri = (await PayjoinUri.Uri.fromStr(pjUriString)).checkPjSupported();
      final minFeeRateSatPerKwu = BigInt.from(networkFeesSatPerVb * 250);
      final senderBuilder = await SenderBuilder.fromPsbtAndUri(
        psbtBase64: originalPsbt,
        pjUri: pjUri,
      );
      final persister = PayjoinSenderPersister.impl();
      final newSender = await senderBuilder.buildRecommended(minFeeRate: minFeeRateSatPerKwu);
      final senderToken = await newSender.persist(persister: persister);

      return Sender.load(token: senderToken, persister: persister);
    } catch (e) {
      throw Exception('Error initializing Payjoin Sender: $e');
    }
  }

  Future<void> spawnNewSender({
    required dynamic sender,
    required String pjUrl,
    required BigInt amount,
    bool isTestnet = false,
  }) async {
    if (sender is! Sender) {
      throw ArgumentError('sender must be an instance of Sender');
    }

    final pjUri = Uri.parse(pjUrl).queryParameters['pj']!;
    await _payjoinStorage!.insertSenderSession(sender, pjUri, _wallet!.id, amount);

    return _spawnSender(isTestnet: isTestnet, sender: sender, pjUri: pjUri);
  }

  Future<void> _spawnSender({
    required Sender sender,
    required String pjUri,
    bool isTestnet = false,
  }) async {
    final completer = Completer();
    final receivePort = ReceivePort();

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        try {
          switch (message['type'] as PayjoinSenderRequestTypes) {
            case PayjoinSenderRequestTypes.requestPosted:
              return;
            case PayjoinSenderRequestTypes.psbtToSign:
              final proposalPsbt = message['psbt'] as String;
              final utxos = _wallet!.getUtxoWithPrivateKeys();
              final finalizedPsbt = await _wallet!.signPsbt(proposalPsbt, utxos);
              final txId = getTxIdFromPsbtV0(finalizedPsbt);
              _wallet!.commitPsbt(finalizedPsbt);

              _cleanupSession(pjUri);
              await _payjoinStorage!.markSenderSessionComplete(pjUri, txId);
              completer.complete();
          }
        } catch (e) {
          _cleanupSession(pjUri);
          await _payjoinStorage!.markSenderSessionUnrecoverable(pjUri, e.toString());
          completer.complete();
        }
      } else if (message is PayjoinSessionError) {
        _cleanupSession(pjUri);
        if (message is UnrecoverableError) {
          await _payjoinStorage!.markSenderSessionUnrecoverable(pjUri, message.message);
          completer.complete();
        } else if (message is RecoverableError) {
          completer.complete();
        } else {
          completer.completeError(message);
        }
      }
    });

    final isolate = await Isolate.spawn(
      PayjoinSenderWorker.run,
      [receivePort.sendPort, sender.toJson(), pjUri],
    );

    _activePollers[pjUri] = PayjoinPollerSession(isolate, receivePort);

    return completer.future;
  }

  Future<Receiver> getUnusedReceiver(String address, [bool isTestnet = false]) async {
    final session = _payjoinStorage!.getUnusedActiveReceiverSession(_wallet!.id);

    if (session != null) {
      await PayjoinUri.Url.fromStr(payjoinDirectoryUrl);

      return Receiver.fromJson(json: session.receiver!);
    }

    return initReceiver(address);
  }

  Future<Receiver> initReceiver(String address, [bool isTestnet = false]) async {
    final ohttpKeys = await PayjoinUri.fetchOhttpKeys(
      ohttpRelay: await randomOhttpRelayUrl(),
      payjoinDirectory: payjoinDirectoryUrl,
    );

    final newReceiver = await NewReceiver.create(
      address: address,
      network: isTestnet ? Network.testnet : Network.bitcoin,
      directory: payjoinDirectoryUrl,
      ohttpKeys: ohttpKeys,
    );
    final persister = PayjoinReceiverPersister.impl();
    final receiverToken = await newReceiver.persist(persister: persister);
    final receiver = await Receiver.load(persister: persister, token: receiverToken);

    await _payjoinStorage!.insertReceiverSession(receiver, _wallet!.id);

    return receiver;
  }

  Future<void> spawnReceiver({
    required dynamic receiver,
    bool isTestnet = false,
  }) async {
    if (receiver is! Receiver) {
      throw ArgumentError('receiver must be an instance of Receiver');
    }

    final completer = Completer();
    final receivePort = ReceivePort();

    SendPort? mainToIsolateSendPort;
    List<UtxoWithPrivateKey> utxos = [];
    String rawAmount = '0';

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        try {
          switch (message['type'] as PayjoinReceiverRequestTypes) {
            case PayjoinReceiverRequestTypes.processOriginalTx:
              final tx = message['tx'] as String;
              rawAmount = getOutputAmountFromTx(tx, _wallet!);
              break;
            case PayjoinReceiverRequestTypes.checkIsOwned:
              (_wallet!.walletAddresses as BitcoinWalletAddresses).newPayjoinReceiver();
              _payjoinStorage!.markReceiverSessionInProgress(receiver.id());

              final inputScript = message['input_script'] as Uint8List;
              final isOwned = _wallet!.isMine(Script.fromRaw(byteData: inputScript));
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': isOwned,
              });
              break;

            case PayjoinReceiverRequestTypes.checkIsReceiverOutput:
              final outputScript = message['output_script'] as Uint8List;
              final isReceiverOutput = _wallet!.isMine(Script.fromRaw(byteData: outputScript));
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': isReceiverOutput,
              });
              break;

            case PayjoinReceiverRequestTypes.getCandidateInputs:
              utxos = _wallet!.getUtxoWithPrivateKeys();
              if (utxos.isEmpty) {
                await _wallet!.updateAllUnspents();
                utxos = _wallet!.getUtxoWithPrivateKeys();
              }
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': utxos,
              });
              break;

            case PayjoinReceiverRequestTypes.processPsbt:
              final psbt = message['psbt'] as String;
              final signedPsbt = await _wallet!.signPsbt(psbt, utxos);
              mainToIsolateSendPort?.send({
                'requestId': message['requestId'],
                'result': signedPsbt,
              });
              break;

            case PayjoinReceiverRequestTypes.proposalSent:
              _cleanupSession(receiver.id());
              final psbt = message['psbt'] as String;
              await _payjoinStorage!
                  .markReceiverSessionComplete(receiver.id(), getTxIdFromPsbtV0(psbt), rawAmount);
              completer.complete();
          }
        } catch (e) {
          _cleanupSession(receiver.id());
          await _payjoinStorage!.markReceiverSessionUnrecoverable(receiver.id(), e.toString());
          completer.completeError(e);
        }
      } else if (message is PayjoinSessionError) {
        _cleanupSession(receiver.id());
        if (message is UnrecoverableError) {
          await _payjoinStorage!.markReceiverSessionUnrecoverable(receiver.id(), message.message);
          completer.complete();
        } else if (message is RecoverableError) {
          completer.complete();
        } else {
          completer.completeError(message);
        }
      } else if (message is SendPort) {
        mainToIsolateSendPort = message;
      }
    });

    final isolate = await Isolate.spawn(
      PayjoinReceiverWorker.run,
      [receivePort.sendPort, receiver.toJson()],
    );

    _activePollers[receiver.id()] = PayjoinPollerSession(isolate, receivePort);

    return completer.future;
  }

  void cleanupSessions() {
    final sessionIds = _activePollers.keys.toList();
    for (final sessionId in sessionIds) {
      _cleanupSession(sessionId);
    }
  }

  void _cleanupSession(String sessionId) {
    _activePollers[sessionId]?.close();
    _activePollers.remove(sessionId);
  }
}
