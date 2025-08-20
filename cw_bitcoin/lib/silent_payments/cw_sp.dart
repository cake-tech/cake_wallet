part of 'sp.dart';

class CWSilentPayments extends SilentPayments {
  @override
Future<void> handleScanSilentPayments(ScanData scanData) async {
  var node = Uri.parse("tcp://electrs.cakewallet.com:50001");

  void log(String message, LogLevel level) {
    printV("[Scanning] $message", file: scanData.debugLogPath, level: level);
  }

  try {
    // if (scanData.shouldSwitchNodes) {
    var scanningClient = await ElectrumProvider.connect(
      ElectrumTCPService.connect(node),
    );
    // }

    log("connected to ${node.toString()}", LogLevel.info);

    int syncHeight = scanData.height;
    int initialSyncHeight = syncHeight;

    final receiver = Receiver(
      scanData.silentAddress.b_scan.toHex(),
      scanData.silentAddress.B_spend.toHex(),
      scanData.network == BitcoinNetwork.testnet,
      scanData.labelIndexes,
      scanData.labelIndexes.length,
    );

    log(
      "using receiver: b_scan: ${scanData.silentAddress.b_scan.toHex()}, B_scan: ${scanData.silentAddress.B_spend.toHex()}, b_spend: ${scanData.silentAddress.B_spend.toHex()}, B_spend: ${scanData.silentAddress.B_spend.toHex()}, network: ${scanData.network.value}, labelIndexes: ${scanData.labelIndexes}",
      LogLevel.info,
    );

    int getCountToScanPerRequest(int syncHeight) {
      if (scanData.isSingleScan) {
        return 1;
      }

      final amountLeft = scanData.chainTip - syncHeight + 1;
      return amountLeft;
    }

    // Initial status UI update, send how many blocks in total to scan
    scanData.sendPort.send(SyncResponse(syncHeight, StartingScanSyncStatus(syncHeight)));

    final req = ElectrumTweaksSubscribe(
      height: syncHeight,
      count: getCountToScanPerRequest(syncHeight),
      historicalMode: false,
    );

    var _scanningStream = await scanningClient.subscribe(req);

    log(
      "initial request: height: $syncHeight, count: ${getCountToScanPerRequest(syncHeight)}",
      LogLevel.info,
    );

    void listenFn(Map<String, dynamic> event, ElectrumTweaksSubscribe req) async {
      final response = req.onResponse(event);

      if (response == null || _scanningStream == null) {
        log(
          "ending: response = $response, stream = $_scanningStream",
          LogLevel.error,
        );
        scanData.sendPort.send(
          SyncResponse(scanData.height, LostConnectionSyncStatus()),
        );
        return;
      }

      // is success or error msg
      final noData = response.message != null;

      if (noData) {
        if (scanData.isSingleScan) {
          log("ending: noData and isSingleScan", LogLevel.info);

          scanData.sendPort.send(
            SyncResponse(scanData.height, LostConnectionSyncStatus()),
          );
          return;
        }

        // re-subscribe to continue receiving messages, starting from the next unscanned height
        final nextHeight = syncHeight + 1;

        if (nextHeight <= scanData.chainTip) {
          log(
            "resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
            LogLevel.info,
          );

          final nextStream = scanningClient.subscribe(
            ElectrumTweaksSubscribe(
              height: nextHeight,
              count: getCountToScanPerRequest(nextHeight),
              historicalMode: false,
            ),
          );

          if (nextStream != null) {
            nextStream.listen((event) => listenFn(event, req));
          } else {
            scanData.sendPort.send(
              SyncResponse(scanData.height, LostConnectionSyncStatus()),
            );
          }
        }

        log(
          "ending: resubscribing: nextHeight: $nextHeight, count: ${getCountToScanPerRequest(nextHeight)}",
          LogLevel.info,
        );
        return;
      }

      final tweakHeight = response.block;

      if (initialSyncHeight < tweakHeight) initialSyncHeight = tweakHeight;

      // Continuous status UI update, send how many blocks left to scan
      final syncingStatus = scanData.isSingleScan
          ? SyncingSyncStatus(1, 0)
          : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, tweakHeight);

      scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

      try {
        final blockTweaks = response.blockTweaks;

        var blockDate = DateTime.now();
        bool isDateNow = true;

        for (final txid in blockTweaks.keys) {
          final tweakData = blockTweaks[txid];
          final outputPubkeys = tweakData!.outputPubkeys;
          final tweak = tweakData.tweak;

          try {
            final addToWallet = {};

            // receivers.forEach((receiver) {
            // NOTE: scanOutputs, from sp_scanner package, called from rust here
            // final scanResult = scanOutputs([outputPubkeys.keys.toList()], tweak, receiver);
            final scanResult = {};

            if (scanResult.isEmpty) {
              continue;
            }

            if (addToWallet[receiver.BSpend] == null) {
              addToWallet[receiver.BSpend] = scanResult;
            } else {
              addToWallet[receiver.BSpend].addAll(scanResult);
            }
            // });

            if (addToWallet.isEmpty) {
              // no results tx, continue to next tx
              continue;
            }

            log(
              "FOUND: addToWallet: ${addToWallet.length}, txid: $txid, tweak: $tweak, height: $tweakHeight",
              LogLevel.info,
            );

            // Every tx in the block has the same date (the block date)
            // So, if blockDate exists, reuse
            if (isDateNow) {
              try {
                final tweakBlockHash = await ProxyWrapper()
                    .get(
                      clearnetUri: Uri.parse(
                        "https://mempool.cakewallet.com/api/v1/block-height/$tweakHeight",
                      ),
                    )
                    .timeout(Duration(seconds: 15));
                final blockResponse = await ProxyWrapper()
                    .get(
                      clearnetUri: Uri.parse(
                        "https://mempool.cakewallet.com/api/v1/block/${tweakBlockHash.body}",
                      ),
                    )
                    .timeout(Duration(seconds: 15));

                if (blockResponse.statusCode == 200 &&
                    blockResponse.body.isNotEmpty &&
                    jsonDecode(blockResponse.body)['timestamp'] != null) {
                  blockDate = DateTime.fromMillisecondsSinceEpoch(
                    int.parse(jsonDecode(blockResponse.body)['timestamp'].toString()) * 1000,
                  );
                  isDateNow = false;
                }
              } catch (e, stacktrace) {
                printV(stacktrace);
                printV(e.toString());
              }
            }

            // initial placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s) on the following loop
            final txInfo = ElectrumTransactionInfo(
              WalletType.bitcoin,
              id: txid,
              height: tweakHeight,
              amount: 0,
              fee: 0,
              direction: TransactionDirection.incoming,
              isReplaced: false,
              // TODO: fetch block data and get the date from it
              date: scanData.network == BitcoinNetwork.mainnet
                  ? (isDateNow ? getDateByBitcoinHeight(tweakHeight) : blockDate)
                  : DateTime.now(),
              confirmations: scanData.chainTip - tweakHeight + 1,
              isReceivedSilentPayment: true,
              isPending: false,
              unspents: [],
            );

            List<BitcoinUnspent> unspents = [];

            addToWallet.forEach((BSpend, scanResultPerLabel) {
              scanResultPerLabel.forEach((label, scanOutput) {
                final labelValue = label == "None" ? null : label.toString();

                (scanOutput as Map<String, dynamic>).forEach((outputPubkey, tweak) {
                  final t_k = tweak as String;

                  final receivingOutputAddress = ECPublic.fromHex(outputPubkey)
                      .toTaprootAddress(tweak: false)
                      .toAddress(scanData.network);

                  final matchingOutput = outputPubkeys[outputPubkey]!;
                  final amount = matchingOutput.amount;
                  final pos = matchingOutput.vout;

                  // final matchingSPWallet = scanData.silentPaymentsWallets.firstWhere(
                  //   (receiver) => receiver.B_spend.toHex() == BSpend.toString(),
                  // );

                  // final labelIndex = labelValue != null ? scanData.labels[label] : 0;
                  // final balance = ElectrumBalance();
                  // balance.confirmed = amount;

                  final receivedAddressRecord = BitcoinSilentPaymentAddressRecord(
                    receivingOutputAddress,
                    index: 0,
                    isHidden: false,
                    isUsed: true,
                    network: scanData.network,
                    silentPaymentTweak: t_k,
                    type: SegwitAddresType.p2tr,
                    txCount: 1,
                    balance: amount,
                  );

                  final unspent = BitcoinSilentPaymentsUnspent(
                    receivedAddressRecord,
                    txid,
                    amount,
                    pos,
                    silentPaymentTweak: t_k,
                    silentPaymentLabel: labelValue,
                  );

                  unspents.add(unspent);
                  txInfo.unspents!.add(unspent);
                  txInfo.amount += unspent.value;
                });
              });
            });

            scanData.sendPort.send({txInfo.id: txInfo});
          } catch (e, stacktrace) {
            scanData.sendPort.send(
              SyncResponse(syncHeight, LostConnectionSyncStatus()),
            );

            log(stacktrace.toString(), LogLevel.error);
            log(e.toString(), LogLevel.error);
            return;
          }
        }
      } catch (e, stacktrace) {
        scanData.sendPort.send(
          SyncResponse(syncHeight, LostConnectionSyncStatus()),
        );

        log(stacktrace.toString(), LogLevel.error);
        log(e.toString(), LogLevel.error);
        return;
      }

      syncHeight = tweakHeight;

      if ((tweakHeight >= scanData.chainTip) || scanData.isSingleScan) {
        if (tweakHeight >= scanData.chainTip)
          scanData.sendPort.send(
            SyncResponse(syncHeight, SyncedTipSyncStatus(scanData.chainTip)),
          );

        if (scanData.isSingleScan) {
          scanData.sendPort.send(SyncResponse(syncHeight, SyncedSyncStatus()));
        }

        _scanningStream?.close();
        _scanningStream = null;
        log(
          "ending: syncHeight: $syncHeight, chainTip: ${scanData.chainTip}, isSingleScan: ${scanData.isSingleScan}",
          LogLevel.info,
        );
        return;
      }
    }

    _scanningStream?.listen((event) => listenFn(event, req));
  } catch (e) {
    log("Error in _handleScanSilentPayments: $e", LogLevel.error);
    scanData.sendPort.send(SyncResponse(scanData.height, LostConnectionSyncStatus()));
  }
}
}
