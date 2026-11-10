part of "electrum_wallet.dart";

class ScanNode {
  ScanNode(this.uri, {required this.useSSL});
  final Uri uri;
  final bool? useSSL;
}

class _ScanWorkerHandle {
  _ScanWorkerHandle(
    this.workerIndex,
    this.isolateFuture, {
    required this.rangeStart,
    required this.rangeEnd,
    required this.historical,
  }) : checkpointBaseline = rangeStart;

  final int workerIndex;
  final Future<Isolate> isolateFuture;
  final int rangeStart;
  final int rangeEnd;
  final bool historical;

  int checkpointBaseline;
  int? pendingCheckpointHeight;
}

class ScanData {
  ScanData({
    required this.workerIndex,
    required this.sendPort,
    required this.silentAddress,
    required this.masterHD,
    required this.height,
    required this.node,
    required this.network,
    required this.chainTip,
    required this.rangeEnd,
    required this.electrumClient,
    required this.transactionHistoryIds,
    required this.labels,
    required this.labelIndexes,
    required this.isSingleScan,
    required this.debugLogPath,
    required this.rescanHeights,
    required this.historical,
    required this.protocolVersion,
  });

  factory ScanData.fromHeight(ScanData scanData, int newHeight) => ScanData(
        workerIndex: scanData.workerIndex,
        sendPort: scanData.sendPort,
        silentAddress: scanData.silentAddress,
        masterHD: scanData.masterHD,
        height: newHeight,
        node: scanData.node,
        network: scanData.network,
        chainTip: scanData.chainTip,
        rangeEnd: scanData.rangeEnd,
        transactionHistoryIds: scanData.transactionHistoryIds,
        electrumClient: scanData.electrumClient,
        labels: scanData.labels,
        labelIndexes: scanData.labelIndexes,
        isSingleScan: scanData.isSingleScan,
        debugLogPath: scanData.debugLogPath,
        rescanHeights: scanData.rescanHeights,
        historical: scanData.historical,
        protocolVersion: scanData.protocolVersion,
      );

  final int workerIndex;
  final SendPort sendPort;
  final SilentPaymentOwner silentAddress;
  final Bip32Slip10Secp256k1 masterHD;
  final int height;
  final ScanNode? node;
  final BasedUtxoNetwork network;

  final int chainTip;
  final electrum.ElectrumClient electrumClient;
  final List<String> transactionHistoryIds;
  final Map<String, String> labels;
  final List<int> labelIndexes;
  final bool isSingleScan;
  final String debugLogPath;
  final List<int>? rescanHeights;

  final int rangeEnd;

  final bool historical;

  final int protocolVersion;
}

class SyncResponse {
  SyncResponse(this.workerIndex, this.height, this.syncStatus);
  final int workerIndex;
  final int height;
  final SyncStatus syncStatus;
}

Future<void> _handleScanSilentPayments(ScanData scanData) async {
  final shouldUpdateSyncStatus = scanData.rescanHeights == null || scanData.rescanHeights!.isEmpty;
  CakeTor.instance = await CakeTorInstance.getInstance();

  final scanNode = scanData.node ?? SilentPaymentsScanner.defaultScanNode;
  final node = scanNode.uri;

  Future<BitcoinBaseElectrumRPCService> dialScanServer() =>
      scanNode.useSSL == true ? ElectrumSSLService.connect(node) : ElectrumTCPService.connect(node);

  void log(String message, LogLevel level) {
    printV(
      "[Scanning worker ${scanData.workerIndex}] $message",
      file: scanData.debugLogPath,
      level: level,
    );
  }

  var highestReportedHeight = scanData.height - 1;

  int? unresolvedHeight;

  void sendSync(int height, SyncStatus status) {
    final blocker = unresolvedHeight;
    if (blocker != null && height >= blocker) {
      height = blocker - 1;
    }
    final clamped = height > highestReportedHeight ? height : highestReportedHeight;
    highestReportedHeight = clamped;
    scanData.sendPort.send(SyncResponse(scanData.workerIndex, clamped, status));
  }

  ElectrumProvider? scanningClient;
  List<ScanSession> sessions = [];

  try {
    var client = await ElectrumProvider.connect(dialScanServer());
    scanningClient = client;

    Future<void> reconnectClient() async {
      try {
        scanningClient?.rpc.disconnect();
      } catch (_) {}
      client = await ElectrumProvider.connect(dialScanServer());
      scanningClient = client;
    }

    log("connected to ${node.toString()}", LogLevel.info);

    final receivers = [
      scanData.network == BitcoinNetwork.testnet
          ? Receiver(
              scanData.masterHD.derivePath(SILENT_PAYMENTS_SCAN_PATH_TESTNET).privateKey.toHex(),
              scanData.masterHD.derivePath(SILENT_PAYMENTS_SPEND_PATH_TESTNET).publicKey.toHex(),
              true,
              scanData.labelIndexes,
              scanData.labelIndexes.length,
            )
          : Receiver(
              scanData.silentAddress.b_scan.toHex(),
              scanData.silentAddress.B_spend.toHex(),
              false,
              scanData.labelIndexes,
              scanData.labelIndexes.length,
            ),
    ];

    log(
      "using receiver: b_scan: ${receivers[0].bScan}, b_spend: ${receivers[0].BSpend}, network: ${scanData.network.value}, labelIndexes: ${scanData.labelIndexes}",
      LogLevel.info,
    );

    sessions = receivers.map(ScanSession.create).toList();

    Future<ElectrumTweaksGetResponse?> fetchTweaksGetWithBackoff({
      required String txid,
      required int vout,
      required int height,
    }) async {
      var backoff = const Duration(seconds: 1);
      const maxBackoff = Duration(seconds: 30);

      while (true) {
        try {
          return await client.request(ElectrumTweaksGet(txid: txid, vout: vout, height: height));
        } on RPCError catch (e) {
          log(
            "tweaks.get permanent failure, dropping match: txid: $txid, vout: $vout, height: $height: $e",
            LogLevel.error,
          );
          return null;
        } catch (e) {
          log(
            "tweaks.get transient failure, retrying in ${backoff.inSeconds}s: txid: $txid, vout: $vout, height: $height: $e",
            LogLevel.error,
          );
          await Future.delayed(backoff);
          if (backoff < maxBackoff) {
            backoff *= 2;
          }
        }
      }
    }

    final blockTimeCache = <int, DateTime>{};

    Future<DateTime> fetchBlockTimeWithBackoff(int height) async {
      final cached = blockTimeCache[height];
      if (cached != null) {
        return cached;
      }

      var backoff = const Duration(seconds: 1);
      const maxBackoff = Duration(seconds: 8);
      const maxAttempts = 4;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final headerHex = await client.request(
            ElectrumRequestBlockHeader(startHeight: height, cpHeight: 0),
            const Duration(seconds: 10),
          ) as String;
          final headerBytes = BytesUtils.fromHexString(headerHex);
          final timestampBytes = headerBytes.sublist(68, 72);
          final timestamp = timestampBytes[0] |
              (timestampBytes[1] << 8) |
              (timestampBytes[2] << 16) |
              (timestampBytes[3] << 24);
          final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          blockTimeCache[height] = date;
          return date;
        } catch (e) {
          log(
            "block.header fetch failed (attempt ${attempt + 1}/$maxAttempts), height: $height: $e",
            LogLevel.error,
          );
          if (attempt < maxAttempts - 1) {
            await Future.delayed(backoff);
            if (backoff < maxBackoff) {
              backoff *= 2;
            }
          }
        }
      }

      return getDateByBitcoinHeight(height);
    }

    Future<void> scan(int syncHeight, {required bool isSingleScan}) async {
      final int initialSyncHeight = syncHeight;

      int? _countCap;

      const _initialCountGuess = 250;

      int getCountToScanPerRequest(int syncHeight) {
        if (isSingleScan) {
          return 1;
        }

        final amountLeft = scanData.rangeEnd - syncHeight + 1;
        final cap = _countCap ?? _initialCountGuess;
        return cap < amountLeft ? cap : amountLeft;
      }

      late void Function(int height) subscribeAndListen;
      late void Function(Object error, StackTrace stackTrace) Function(
        int height, [
        Stream<Object>? source,
      ]) onSubscribeError;

      final idleTimeout =
          scanData.historical ? const Duration(seconds: 60) : const Duration(minutes: 2);
      var lastActivity = DateTime.now();
      var eventsInFlight = 0;
      var scannedAny = false;
      Timer? watchdog;

      if (shouldUpdateSyncStatus) {
        sendSync(syncHeight, StartingScanSyncStatus(syncHeight));
      }

      final req = ElectrumTweaksSubscribe(
        height: syncHeight,
        count: getCountToScanPerRequest(syncHeight),
        historicalMode: scanData.historical,
        protocolVersion: scanData.protocolVersion >= 2 ? scanData.protocolVersion : null,
      );

      var _scanningStream = client.subscribe(req);

      log(
        "initial request: height: $syncHeight, count: ${getCountToScanPerRequest(syncHeight)}",
        LogLevel.info,
      );

      void endScanningSuccesfully() {
        if (isSingleScan) {
          sendSync(syncHeight, SyncedSyncStatus());
        } else {
          sendSync(syncHeight, SyncedTipSyncStatus(scanData.rangeEnd));
        }

        _scanningStream?.close();
        _scanningStream = null;
        watchdog?.cancel();

        log(
          "ended: syncHeight: $syncHeight, rangeEnd: ${scanData.rangeEnd}, isSingleScan: ${isSingleScan}",
          LogLevel.info,
        );
      }

      Future<bool> processTweaksV2Block(List<int> blockBytes, int blockHeight) async {
        final bytes = Uint8List.fromList(blockBytes);
        final matchesByTxid = <String, List<Map<String, dynamic>>>{};

        for (var i = 0; i < sessions.length; i++) {
          final rawMatches = sessions[i].scanBlock(bytes);
          for (final raw in rawMatches) {
            final match = raw as Map<String, dynamic>;
            matchesByTxid
                .putIfAbsent(match["txid"] as String, () => [])
                .add({...match, "_receiverIndex": i});
          }
        }

        for (final entry in matchesByTxid.entries) {
          final txid = entry.key;
          final matches = entry.value;
          final matchHeight = matches.first["height"] as int;

          try {
            final txInfo = ElectrumTransactionInfo(
              WalletType.bitcoin,
              id: txid,
              height: matchHeight,
              amount: Money.zero(CryptoCurrency.btc),
              fee: Money.zero(CryptoCurrency.btc),
              direction: TransactionDirection.incoming,
              isReplaced: false,
              date: await fetchBlockTimeWithBackoff(matchHeight),
              confirmations: scanData.chainTip - matchHeight + 1,
              isReceivedSilentPayment: true,
              isPending: false,
              unspents: [],
            );

            for (final match in matches) {
              final vout = match["vout"] as int;
              final outputPubkey = match["output_pubkey"] as String;
              final label = match["label"] as String;
              final tweak = match["tweak"] as String;

              final fetched = await fetchTweaksGetWithBackoff(
                txid: txid,
                vout: vout,
                height: matchHeight,
              );

              if (fetched == null) {
                if (unresolvedHeight == null || matchHeight < unresolvedHeight!) {
                  unresolvedHeight = matchHeight;
                }
                return false;
              }
              txInfo.amount += Money.fromInt(fetched.amount, txInfo.amount.currency);

              if (fetched.spent) {
                continue;
              }

              final labelValue = label == "None" ? null : label;
              final receivingOutputAddress = ECPublic.fromHex(outputPubkey)
                  .toTaprootAddress(tweak: false)
                  .toAddress(scanData.network);

              final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                receivingOutputAddress,
                index: 0,
                isHidden: false,
                isUsed: true,
                network: scanData.network,
                silentPaymentTweak: tweak,
                type: SegwitAddresType.p2tr,
                txCount: 1,
                balance: fetched.amount,
                spendDerivationPath: scanData.network == BitcoinNetwork.testnet
                    ? SILENT_PAYMENTS_SPEND_PATH_TESTNET
                    : SILENT_PAYMENTS_SPEND_PATH,
              );

              final unspent = BitcoinSilentPaymentsUnspent(
                receivedAddressRecord,
                txid,
                fetched.amount,
                vout,
                silentPaymentTweak: tweak,
                silentPaymentLabel: labelValue,
              );

              txInfo.unspents!.add(unspent);
            }

            log(
              "FOUND (v2): txid: $txid, matches: ${matches.length}, height: $matchHeight",
              LogLevel.info,
            );
            scanData.sendPort.send({txInfo.id: txInfo});
          } catch (e, stacktrace) {
            if (shouldUpdateSyncStatus) {
              sendSync(syncHeight, LostConnectionSyncStatus());
            }

            log(stacktrace.toString(), LogLevel.error);
            log(e.toString(), LogLevel.error);
          }
        }

        return true;
      }

      late final void Function(Map<String, dynamic> event, ElectrumTweaksSubscribe req) listenFn;

      var _processingChain = Future<void>.value();

      final requestsWithData = <ElectrumTweaksSubscribe>{};

      final requestsAlreadyResubscribed = <ElectrumTweaksSubscribe>{};

      void resubscribeToNextHeight(ElectrumTweaksSubscribe req) {
        if (!requestsAlreadyResubscribed.add(req)) {
          return;
        }

        if (isSingleScan) {
          log("ending: isSingleScan", LogLevel.info);
          endScanningSuccesfully();
          return;
        }

        final nextHeight = syncHeight + 1;

        if (nextHeight <= scanData.rangeEnd) {
          log(
            "resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
            LogLevel.info,
          );

          _scanningStream?.close();
          _scanningStream = null;

          final nextReq = ElectrumTweaksSubscribe(
            height: nextHeight,
            count: getCountToScanPerRequest(nextHeight),
            historicalMode: scanData.historical,
            protocolVersion: scanData.protocolVersion >= 2 ? scanData.protocolVersion : null,
          );
          final nextStream = client.subscribe(nextReq);

          if (nextStream != null) {
            _scanningStream = nextStream;
            nextStream.listen(
              (event) => listenFn(event, nextReq),
              onError: onSubscribeError(nextHeight, nextStream),
            );
          } else {
            if (shouldUpdateSyncStatus) {
              sendSync(scanData.height, LostConnectionSyncStatus());
            }
          }
        }

        log(
          "ending: resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
          LogLevel.info,
        );
      }

      Future<void> _processEvent(Map<String, dynamic> event, ElectrumTweaksSubscribe req) async {
        final response = req.onResponse(event);

        if (response == null) {
          if (_scanningStream != null) {
            if (!isSingleScan && !requestsWithData.contains(req) && req.count > 1) {
              if (_countCap != null && req.count > _countCap!) {
                return;
              }

              _countCap = req.count ~/ 2 < 1 ? 1 : req.count ~/ 2;
              subscribeAndListen(req.height);

              return;
            }
            resubscribeToNextHeight(req);
          }
          return;
        }

        if (_scanningStream == null) {
          log(
            "ending: response = $response, stream = $_scanningStream",
            LogLevel.error,
          );
          return;
        }

        final noData = response.message != null;

        if (noData) {
          resubscribeToNextHeight(req);
          return;
        }

        requestsWithData.add(req);

        if (response.tweaksV2Bytes != null) {
          final v2Bytes = response.tweaksV2Bytes!;
          if (v2Bytes.length < 5) {
            if (shouldUpdateSyncStatus) {
              sendSync(syncHeight, LostConnectionSyncStatus());
            }
            log("v2 blob too short to contain a height: ${v2Bytes.length} bytes", LogLevel.error);
            return;
          }

          final tweakHeight =
              ByteData.sublistView(Uint8List.fromList(v2Bytes), 0, 4).getUint32(0, Endian.little);

          if (tweakHeight < syncHeight) {
            return;
          }

          final syncingStatus = isSingleScan
              ? SyncingSyncStatus(1, 0)
              : SyncingSyncStatus.fromHeightValues(
                  scanData.rangeEnd,
                  initialSyncHeight,
                  tweakHeight,
                );
          if (shouldUpdateSyncStatus) {
            sendSync(syncHeight, syncingStatus);
          }

          final completed = await processTweaksV2Block(v2Bytes, tweakHeight);
          if (!completed) {
            return;
          }

          scannedAny = true;
          if (tweakHeight > syncHeight) {
            syncHeight = tweakHeight;
          }
          if ((tweakHeight >= scanData.rangeEnd) || isSingleScan) {
            endScanningSuccesfully();
          }
          return;
        }

        final tweakHeight = response.block;

        if (tweakHeight < syncHeight) {
          return;
        }

        final syncingStatus = isSingleScan
            ? SyncingSyncStatus(1, 0)
            : SyncingSyncStatus.fromHeightValues(scanData.rangeEnd, initialSyncHeight, tweakHeight);

        if (shouldUpdateSyncStatus) {
          sendSync(syncHeight, syncingStatus);
        }

        try {
          final blockTweaks = response.blockTweaks;

          for (final txid in blockTweaks.keys) {
            final tweakData = blockTweaks[txid];
            final outputPubkeys = tweakData!.outputPubkeys;
            final tweak = tweakData.tweak;

            try {
              final addToWallet = <String, dynamic>{};

              for (var i = 0; i < receivers.length; i++) {
                final receiver = receivers[i];
                final session = sessions[i];
                final preparedList = outputPubkeys.keys.toList().map((e) => [e]).toList();
                final scanResult = session.scan(preparedList, tweak);

                if (scanResult.isEmpty) {
                  continue;
                }

                if (addToWallet[receiver.BSpend] == null) {
                  addToWallet[receiver.BSpend] = scanResult;
                } else {
                  addToWallet[receiver.BSpend].addAll(scanResult);
                }
              }

              if (addToWallet.isEmpty) {
                continue;
              }

              log(
                "FOUND: addToWallet: ${addToWallet.length}, txid: $txid, tweak: $tweak, height: $tweakHeight",
                LogLevel.info,
              );

              final txInfo = ElectrumTransactionInfo(
                WalletType.bitcoin,
                id: txid,
                height: tweakHeight,
                amount: Money.zero(CryptoCurrency.btc),
                fee: Money.zero(CryptoCurrency.btc),
                direction: TransactionDirection.incoming,
                isReplaced: false,
                date: await fetchBlockTimeWithBackoff(tweakHeight),
                confirmations: scanData.chainTip - tweakHeight + 1,
                isReceivedSilentPayment: true,
                isPending: false,
                unspents: [],
              );

              final List<BitcoinUnspent> unspents = [];

              addToWallet.forEach((bSpend, scanResultPerLabel) {
                scanResultPerLabel.forEach((label, scanOutput) {
                  final labelValue = label == "None" ? null : label.toString();

                  (scanOutput as Map<String, dynamic>).forEach((outputPubkey, tweak) {
                    final tK = tweak as String;

                    final receivingOutputAddress = ECPublic.fromHex(outputPubkey)
                        .toTaprootAddress(tweak: false)
                        .toAddress(scanData.network);

                    final matchingOutput = outputPubkeys[outputPubkey]!;
                    final amount = matchingOutput.amount;
                    final pos = matchingOutput.vout;
                    final spent = matchingOutput.spendingInput;


                    final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                      receivingOutputAddress,
                      index: 0,
                      isHidden: false,
                      isUsed: true,
                      network: scanData.network,
                      silentPaymentTweak: tK,
                      type: SegwitAddresType.p2tr,
                      txCount: 1,
                      balance: amount,
                      spendDerivationPath: scanData.network == BitcoinNetwork.testnet
                          ? SILENT_PAYMENTS_SPEND_PATH_TESTNET
                          : SILENT_PAYMENTS_SPEND_PATH,
                    );

                    final unspent = BitcoinSilentPaymentsUnspent(
                      receivedAddressRecord,
                      txid,
                      amount,
                      pos,
                      silentPaymentTweak: tK,
                      silentPaymentLabel: labelValue,
                    );

                    if (spent == null) {
                      unspents.add(unspent);
                      txInfo.unspents!.add(unspent);
                    }

                    txInfo.amount += Money.fromInt(unspent.value, txInfo.amount.currency);
                  });
                });
              });

              scanData.sendPort.send({txInfo.id: txInfo});
            } catch (e, stacktrace) {
              if (shouldUpdateSyncStatus) {
                sendSync(syncHeight, LostConnectionSyncStatus());
              }

              log(stacktrace.toString(), LogLevel.error);
              log(e.toString(), LogLevel.error);
              return;
            }
          }
        } catch (e, stacktrace) {
          if (shouldUpdateSyncStatus) {
            sendSync(syncHeight, LostConnectionSyncStatus());
          }

          log(stacktrace.toString(), LogLevel.error);
          log(e.toString(), LogLevel.error);
          return;
        }

        scannedAny = true;
        if (tweakHeight > syncHeight) {
          syncHeight = tweakHeight;
        }

        if ((tweakHeight >= scanData.rangeEnd) || isSingleScan) {
          endScanningSuccesfully();
        }
      }

      listenFn = (event, req) {
        lastActivity = DateTime.now();
        eventsInFlight++;
        _processingChain = _processingChain
            .then((_) => _processEvent(event, req))
            .catchError((e, stacktrace) {
          log("_processEvent failed: $e", LogLevel.error);
          log(stacktrace.toString(), LogLevel.error);
        }).whenComplete(() {
          eventsInFlight--;
          lastActivity = DateTime.now();
        });
      };

      subscribeAndListen = (height) {
        final retryReq = ElectrumTweaksSubscribe(
          height: height,
          count: getCountToScanPerRequest(height),
          historicalMode: scanData.historical,
          protocolVersion: scanData.protocolVersion >= 2 ? scanData.protocolVersion : null,
        );
        final stream = client.subscribe(retryReq);
        if (stream == null) {
          if (shouldUpdateSyncStatus) {
            sendSync(height, LostConnectionSyncStatus());
          }
          return;
        }
        _scanningStream?.close();
        _scanningStream = stream;
        lastActivity = DateTime.now();
        stream.listen(
          (event) => listenFn(event, retryReq),
          onError: onSubscribeError(height, stream),
        );
      };

      onSubscribeError = (height, [source]) => (error, stackTrace) async {
            if (source != null && !identical(source, _scanningStream)) {
              return;
            }

            final message = error.toString();
            final tooLarge = message.contains("exceeds") && message.contains("cap");
            final current = getCountToScanPerRequest(height);

            if (tooLarge && current > 1) {
              _countCap = current ~/ 2 < 1 ? 1 : current ~/ 2;
              log(
                "subscribe rejected as too large (count=$current), retrying height $height with count $_countCap: $error",
                LogLevel.warn,
              );
              subscribeAndListen(height);
              return;
            }

            log("subscribe error at height $height: $error", LogLevel.error);
            log(stackTrace.toString(), LogLevel.error);
            if (shouldUpdateSyncStatus) {
              sendSync(height, LostConnectionSyncStatus());
            }

            unawaited(_scanningStream?.close());
            _scanningStream = null;

            var backoff = const Duration(seconds: 1);
            const maxBackoff = Duration(seconds: 30);
            while (true) {
              try {
                await reconnectClient();
                log("reconnected after subscribe error, resuming at height $height", LogLevel.info);
                subscribeAndListen(height);
                return;
              } catch (e) {
                log(
                  "reconnect after subscribe error failed, retrying in ${backoff.inSeconds}s: $e",
                  LogLevel.error,
                );
                await Future.delayed(backoff);
                if (backoff < maxBackoff) {
                  backoff *= 2;
                }
              }
            }
          };

      _scanningStream?.listen(
        (event) => listenFn(event, req),
        onError: onSubscribeError(syncHeight, _scanningStream),
      );

      watchdog = Timer.periodic(const Duration(seconds: 15), (_) {
        if (_scanningStream == null || eventsInFlight > 0) {
          return;
        }
        if (DateTime.now().difference(lastActivity) < idleTimeout) {
          return;
        }

        final resumeHeight = scannedAny ? syncHeight + 1 : syncHeight;
        log(
          "no scan data for ${idleTimeout.inSeconds}s, reconnecting at height $resumeHeight",
          LogLevel.warn,
        );
        onSubscribeError(resumeHeight)(
          TimeoutException("scan subscription idle", idleTimeout),
          StackTrace.current,
        );
      });
    }

    if (scanData.rescanHeights != null) {
      for (final height in scanData.rescanHeights!) {
        log("rescanning from height: $height", LogLevel.info);
        unawaited(scan(height, isSingleScan: true));
      }
    } else {
      unawaited(scan(scanData.height, isSingleScan: scanData.isSingleScan));
    }
  } catch (e) {
    log("Error in _handleScanSilentPayments: $e", LogLevel.error);
    if (shouldUpdateSyncStatus) {
      sendSync(scanData.height, LostConnectionSyncStatus());
    }
    for (final session in sessions) {
      session.dispose();
    }
    scanningClient?.rpc.disconnect();
  }
}
