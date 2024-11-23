import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_methods.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_params.dart';
import 'package:cw_bitcoin/electrum_worker/methods/methods.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:http/http.dart' as http;
import 'package:sp_scanner/sp_scanner.dart';

class ElectrumWorker {
  final SendPort sendPort;
  ElectrumApiProvider? _electrumClient;
  BasedUtxoNetwork? _network;
  bool _isScanning = false;
  bool _stopScanRequested = false;

  ElectrumWorker._(this.sendPort, {ElectrumApiProvider? electrumClient})
      : _electrumClient = electrumClient;

  static void run(SendPort sendPort) {
    final worker = ElectrumWorker._(sendPort);
    final receivePort = ReceivePort();

    sendPort.send(receivePort.sendPort);

    receivePort.listen(worker.handleMessage);
  }

  void _sendResponse<T, U>(ElectrumWorkerResponse<T, U> response) {
    sendPort.send(jsonEncode(response.toJson()));
  }

  void _sendError(ElectrumWorkerErrorResponse response) {
    sendPort.send(jsonEncode(response.toJson()));
  }

  void handleMessage(dynamic message) async {
    try {
      Map<String, dynamic> messageJson;
      if (message is String) {
        messageJson = jsonDecode(message) as Map<String, dynamic>;
      } else {
        messageJson = message as Map<String, dynamic>;
      }
      final workerMethod = messageJson['method'] as String;

      switch (workerMethod) {
        case ElectrumWorkerMethods.connectionMethod:
          await _handleConnect(
            ElectrumWorkerConnectionRequest.fromJson(messageJson),
          );
          break;
        case ElectrumWorkerMethods.txHashMethod:
          await _handleGetTxExpanded(
            ElectrumWorkerTxExpandedRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.headersSubscribeMethod:
          await _handleHeadersSubscribe(
            ElectrumWorkerHeadersSubscribeRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.scripthashesSubscribeMethod:
          await _handleScriphashesSubscribe(
            ElectrumWorkerScripthashesSubscribeRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.getBalanceMethod:
          await _handleGetBalance(
            ElectrumWorkerGetBalanceRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.getHistoryMethod:
          await _handleGetHistory(
            ElectrumWorkerGetHistoryRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.listunspentMethod:
          await _handleListUnspent(
            ElectrumWorkerListUnspentRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.broadcastMethod:
          await _handleBroadcast(
            ElectrumWorkerBroadcastRequest.fromJson(messageJson),
          );
          break;
        case ElectrumWorkerMethods.checkTweaksMethod:
          await _handleCheckTweaks(
            ElectrumWorkerCheckTweaksRequest.fromJson(messageJson),
          );
          break;
        case ElectrumWorkerMethods.stopScanningMethod:
          await _handleStopScanning(
            ElectrumWorkerStopScanningRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.estimateFeeMethod:
        case ElectrumRequestMethods.tweaksSubscribeMethod:
          if (_isScanning) {
            _stopScanRequested = false;
          }

          if (!_stopScanRequested) {
            await _handleScanSilentPayments(
              ElectrumWorkerTweaksSubscribeRequest.fromJson(messageJson),
            );
          } else {
            _stopScanRequested = false;
            _sendResponse(
              ElectrumWorkerTweaksSubscribeResponse(
                result: TweaksSyncResponse(syncStatus: SyncedSyncStatus()),
              ),
            );
          }

          break;
        case ElectrumRequestMethods.estimateFeeMethod:
          await _handleGetFeeRates(
            ElectrumWorkerGetFeesRequest.fromJson(messageJson),
          );
          break;
        case ElectrumRequestMethods.versionMethod:
          await _handleGetVersion(
            ElectrumWorkerGetVersionRequest.fromJson(messageJson),
          );
          break;
      }
    } catch (e) {
      _sendError(ElectrumWorkerErrorResponse(error: e.toString()));
    }
  }

  Future<void> _handleConnect(ElectrumWorkerConnectionRequest request) async {
    _network = request.network;

    try {
      _electrumClient = await ElectrumApiProvider.connect(
        request.useSSL
            ? ElectrumSSLService.connect(
                request.uri,
                onConnectionStatusChange: (status) {
                  _sendResponse(
                    ElectrumWorkerConnectionResponse(status: status, id: request.id),
                  );
                },
              )
            : ElectrumTCPService.connect(
                request.uri,
                onConnectionStatusChange: (status) {
                  _sendResponse(
                    ElectrumWorkerConnectionResponse(status: status, id: request.id),
                  );
                },
              ),
      );
    } catch (e) {
      _sendError(ElectrumWorkerConnectionError(error: e.toString()));
    }
  }

  Future<void> _handleHeadersSubscribe(ElectrumWorkerHeadersSubscribeRequest request) async {
    final req = ElectrumHeaderSubscribe();

    final stream = _electrumClient!.subscribe(req);
    if (stream == null) {
      _sendError(ElectrumWorkerHeadersSubscribeError(error: 'Failed to subscribe'));
      return;
    }

    stream.listen((event) {
      _sendResponse(
        ElectrumWorkerHeadersSubscribeResponse(
          result: req.onResponse(event),
          id: request.id,
        ),
      );
    });
  }

  Future<void> _handleScriphashesSubscribe(
    ElectrumWorkerScripthashesSubscribeRequest request,
  ) async {
    await Future.wait(request.scripthashByAddress.entries.map((entry) async {
      final address = entry.key;
      final scripthash = entry.value;

      final req = ElectrumScriptHashSubscribe(scriptHash: scripthash);

      final stream = await _electrumClient!.subscribe(req);

      if (stream == null) {
        _sendError(ElectrumWorkerScripthashesSubscribeError(error: 'Failed to subscribe'));
        return;
      }

      // https://electrumx.readthedocs.io/en/latest/protocol-basics.html#status
      // The status of the script hash is the hash of the tx history, or null if the string is empty because there are no transactions
      stream.listen((status) async {
        print("status: $status");

        _sendResponse(ElectrumWorkerScripthashesSubscribeResponse(
          result: {address: req.onResponse(status)},
          id: request.id,
        ));
      });
    }));
  }

  Future<void> _handleGetHistory(ElectrumWorkerGetHistoryRequest result) async {
    final Map<String, AddressHistoriesResponse> histories = {};
    final addresses = result.addresses;

    await Future.wait(addresses.map((addressRecord) async {
      final history = await _electrumClient!.request(ElectrumScriptHashGetHistory(
        scriptHash: addressRecord.scriptHash,
      ));

      if (history.isNotEmpty) {
        addressRecord.setAsUsed();
        addressRecord.txCount = history.length;

        await Future.wait(history.map((transaction) async {
          final txid = transaction['tx_hash'] as String;
          final height = transaction['height'] as int;
          ElectrumTransactionInfo? tx;

          try {
            // Exception thrown on null, handled on catch
            tx = result.storedTxs.firstWhere((tx) => tx.id == txid);

            if (height > 0) {
              tx.height = height;

              // the tx's block itself is the first confirmation so add 1
              tx.confirmations = result.chainTip - height + 1;
              tx.isPending = tx.confirmations == 0;
            }
          } catch (_) {}

          // date is validated when the API responds with the same date at least twice
          // since sometimes the mempool api returns the wrong date at first, and we update
          if (tx?.isDateValidated != true) {
            tx = ElectrumTransactionInfo.fromElectrumBundle(
              await _getTransactionExpanded(
                hash: txid,
                currentChainTip: result.chainTip,
                mempoolAPIEnabled: result.mempoolAPIEnabled,
                getTime: true,
                confirmations: tx?.confirmations,
                date: tx?.date,
              ),
              result.walletType,
              result.network,
              addresses: result.addresses.map((addr) => addr.address).toSet(),
              height: height,
            );
          }

          final addressHistories = histories[addressRecord.address];
          if (addressHistories != null) {
            addressHistories.txs.add(tx!);
          } else {
            histories[addressRecord.address] = AddressHistoriesResponse(
              addressRecord: addressRecord,
              txs: [tx!],
              walletType: result.walletType,
            );
          }

          return Future.value(null);
        }));
      }

      return histories;
    }));

    _sendResponse(ElectrumWorkerGetHistoryResponse(
      result: histories.values.toList(),
      id: result.id,
    ));
  }

  // Future<void> _handleListUnspents(ElectrumWorkerGetBalanceRequest request) async {
  //   final balanceFutures = <Future<Map<String, dynamic>>>[];

  //   for (final scripthash in request.scripthashes) {
  //     final balanceFuture = _electrumClient!.request(
  //       ElectrumGetScriptHashBalance(scriptHash: scripthash),
  //     );
  //     balanceFutures.add(balanceFuture);
  //   }

  //   var totalConfirmed = 0;
  //   var totalUnconfirmed = 0;

  //   final balances = await Future.wait(balanceFutures);

  //   for (final balance in balances) {
  //     final confirmed = balance['confirmed'] as int? ?? 0;
  //     final unconfirmed = balance['unconfirmed'] as int? ?? 0;
  //     totalConfirmed += confirmed;
  //     totalUnconfirmed += unconfirmed;
  //   }

  //   _sendResponse(ElectrumWorkerGetBalanceResponse(
  //     result: ElectrumBalance(
  //       confirmed: totalConfirmed,
  //       unconfirmed: totalUnconfirmed,
  //       frozen: 0,
  //     ),
  //   ));
  // }

  Future<void> _handleGetBalance(ElectrumWorkerGetBalanceRequest request) async {
    final balanceFutures = <Future<Map<String, dynamic>>>[];

    for (final scripthash in request.scripthashes) {
      final balanceFuture = _electrumClient!.request(
        ElectrumGetScriptHashBalance(scriptHash: scripthash),
      );
      balanceFutures.add(balanceFuture);
    }

    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    final balances = await Future.wait(balanceFutures);

    for (final balance in balances) {
      final confirmed = balance['confirmed'] as int? ?? 0;
      final unconfirmed = balance['unconfirmed'] as int? ?? 0;
      totalConfirmed += confirmed;
      totalUnconfirmed += unconfirmed;
    }

    _sendResponse(
      ElectrumWorkerGetBalanceResponse(
        result: ElectrumBalance(
          confirmed: totalConfirmed,
          unconfirmed: totalUnconfirmed,
          frozen: 0,
        ),
        id: request.id,
      ),
    );
  }

  Future<void> _handleListUnspent(ElectrumWorkerListUnspentRequest request) async {
    final unspents = <String, List<ElectrumUtxo>>{};

    await Future.wait(request.scripthashes.map((scriptHash) async {
      final scriptHashUnspents = await _electrumClient!.request(
        ElectrumScriptHashListUnspent(scriptHash: scriptHash),
      );

      if (scriptHashUnspents.isNotEmpty) {
        unspents[scriptHash] = scriptHashUnspents;
      }
    }));

    _sendResponse(ElectrumWorkerListUnspentResponse(utxos: unspents, id: request.id));
  }

  Future<void> _handleBroadcast(ElectrumWorkerBroadcastRequest request) async {
    final txHash = await _electrumClient!.request(
      ElectrumBroadCastTransaction(transactionRaw: request.transactionRaw),
    );

    _sendResponse(ElectrumWorkerBroadcastResponse(txHash: txHash, id: request.id));
  }

  Future<void> _handleGetTxExpanded(ElectrumWorkerTxExpandedRequest request) async {
    final tx = await _getTransactionExpanded(
      hash: request.txHash,
      currentChainTip: request.currentChainTip,
      mempoolAPIEnabled: false,
    );

    _sendResponse(ElectrumWorkerTxExpandedResponse(expandedTx: tx, id: request.id));
  }

  Future<ElectrumTransactionBundle> _getTransactionExpanded({
    required String hash,
    required int currentChainTip,
    required bool mempoolAPIEnabled,
    bool getTime = false,
    int? confirmations,
    DateTime? date,
  }) async {
    int? time;
    int? height;
    bool? isDateValidated;

    final transactionHex = await _electrumClient!.request(
      ElectrumGetTransactionHex(transactionHash: hash),
    );

    if (getTime) {
      if (mempoolAPIEnabled) {
        try {
          final txVerbose = await http.get(
            Uri.parse(
              "http://mempool.cakewallet.com:8999/api/v1/tx/$hash/status",
            ),
          );

          if (txVerbose.statusCode == 200 &&
              txVerbose.body.isNotEmpty &&
              jsonDecode(txVerbose.body) != null) {
            height = jsonDecode(txVerbose.body)['block_height'] as int;

            final blockHash = await http.get(
              Uri.parse(
                "http://mempool.cakewallet.com:8999/api/v1/block-height/$height",
              ),
            );

            if (blockHash.statusCode == 200 && blockHash.body.isNotEmpty) {
              final blockResponse = await http.get(
                Uri.parse(
                  "http://mempool.cakewallet.com:8999/api/v1/block/${blockHash.body}",
                ),
              );

              if (blockResponse.statusCode == 200 &&
                  blockResponse.body.isNotEmpty &&
                  jsonDecode(blockResponse.body)['timestamp'] != null) {
                time = int.parse(jsonDecode(blockResponse.body)['timestamp'].toString());

                if (date != null) {
                  final newDate = DateTime.fromMillisecondsSinceEpoch(time * 1000);
                  isDateValidated = newDate == date;
                }
              }
            }
          }
        } catch (_) {}
      }

      if (confirmations == null && height != null) {
        final tip = currentChainTip;
        if (tip > 0 && height > 0) {
          // Add one because the block itself is the first confirmation
          confirmations = tip - height + 1;
        }
      }
    }

    final original = BtcTransaction.fromRaw(transactionHex);
    final ins = <BtcTransaction>[];

    for (final vin in original.inputs) {
      final inputTransactionHex = await _electrumClient!.request(
        // TODO: _getTXHex
        ElectrumGetTransactionHex(transactionHash: vin.txId),
      );

      ins.add(BtcTransaction.fromRaw(inputTransactionHex));
    }

    return ElectrumTransactionBundle(
      original,
      ins: ins,
      time: time,
      confirmations: confirmations ?? 0,
      isDateValidated: isDateValidated,
    );
  }

  Future<void> _handleGetFeeRates(ElectrumWorkerGetFeesRequest request) async {
    if (request.mempoolAPIEnabled) {
      try {
        final recommendedFees = await ApiProvider.fromMempool(
          _network!,
          baseUrl: "http://mempool.cakewallet.com:8999/api",
        ).getRecommendedFeeRate();

        final unimportantFee = recommendedFees.economyFee!.satoshis;
        final normalFee = recommendedFees.low.satoshis;
        int elevatedFee = recommendedFees.medium.satoshis;
        int priorityFee = recommendedFees.high.satoshis;

        // Bitcoin only: adjust fee rates to avoid equal fee values
        // elevated fee should be higher than normal fee
        if (normalFee == elevatedFee) {
          elevatedFee++;
        }
        // priority fee should be higher than elevated fee
        while (priorityFee <= elevatedFee) {
          priorityFee++;
        }
        // this guarantees that, even if all fees are low and equal,
        // higher priority fee txs can be consumed when chain fees start surging

        _sendResponse(
          ElectrumWorkerGetFeesResponse(
            result: BitcoinTransactionPriorities(
              unimportant: unimportantFee,
              normal: normalFee,
              elevated: elevatedFee,
              priority: priorityFee,
              custom: unimportantFee,
            ),
          ),
        );
      } catch (e) {
        _sendError(ElectrumWorkerGetFeesError(error: e.toString()));
      }
    } else {
      _sendResponse(
        ElectrumWorkerGetFeesResponse(
          result: ElectrumTransactionPriorities.fromList(
            await _electrumClient!.getFeeRates(),
          ),
        ),
      );
    }
  }

  Future<void> _handleCheckTweaks(ElectrumWorkerCheckTweaksRequest request) async {
    final response = await _electrumClient!.request(
      ElectrumTweaksSubscribe(
        height: 0,
        count: 1,
        historicalMode: false,
      ),
    );

    final supportsScanning = response != null;
    _sendResponse(
      ElectrumWorkerCheckTweaksResponse(result: supportsScanning, id: request.id),
    );
  }

  Future<void> _handleStopScanning(ElectrumWorkerStopScanningRequest request) async {
    _stopScanRequested = true;
    _sendResponse(
      ElectrumWorkerStopScanningResponse(result: true, id: request.id),
    );
  }

  Future<void> _handleScanSilentPayments(ElectrumWorkerTweaksSubscribeRequest request) async {
    _isScanning = true;
    final scanData = request.scanData;

    // TODO: confirmedSwitch use new connection
    // final _electrumClient = await ElectrumApiProvider.connect(
    //   ElectrumTCPService.connect(
    //     Uri.parse("tcp://electrs.cakewallet.com:50001"),
    //     onConnectionStatusChange: (status) {
    //       _sendResponse(
    //         ElectrumWorkerConnectionResponse(status: status, id: request.id),
    //       );
    //     },
    //   ),
    // );

    int syncHeight = scanData.height;
    int initialSyncHeight = syncHeight;

    final receivers = scanData.silentPaymentsWallets.map(
      (wallet) {
        return Receiver(
          wallet.b_scan.toHex(),
          wallet.B_spend.toHex(),
          scanData.network == BitcoinNetwork.testnet,
          scanData.labelIndexes,
          scanData.labelIndexes.length,
        );
      },
    );

    // Initial status UI update, send how many blocks in total to scan
    _sendResponse(ElectrumWorkerTweaksSubscribeResponse(
      result: TweaksSyncResponse(
        height: syncHeight,
        syncStatus: StartingScanSyncStatus(syncHeight),
      ),
    ));

    final req = ElectrumTweaksSubscribe(
      height: syncHeight,
      count: 1,
      historicalMode: false,
    );

    final stream = await _electrumClient!.subscribe(req);

    void listenFn(Map<String, dynamic> event, ElectrumTweaksSubscribe req) {
      final response = req.onResponse(event);
      if (_stopScanRequested || response == null) {
        _stopScanRequested = false;
        _isScanning = false;
        return;
      }

      // success or error msg
      final noData = response.message != null;

      if (noData) {
        if (scanData.isSingleScan) {
          return;
        }

        // re-subscribe to continue receiving messages, starting from the next unscanned height
        final nextHeight = syncHeight + 1;

        if (nextHeight <= scanData.chainTip) {
          final nextStream = _electrumClient!.subscribe(
            ElectrumTweaksSubscribe(
              height: nextHeight,
              count: 1,
              historicalMode: false,
            ),
          );
          nextStream?.listen((event) => listenFn(event, req));
        }

        return;
      }

      // Continuous status UI update, send how many blocks left to scan
      final syncingStatus = scanData.isSingleScan
          ? SyncingSyncStatus(1, 0)
          : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, syncHeight);
      _sendResponse(ElectrumWorkerTweaksSubscribeResponse(
        result: TweaksSyncResponse(height: syncHeight, syncStatus: syncingStatus),
      ));

      final tweakHeight = response.block;

      try {
        final blockTweaks = response.blockTweaks;

        for (final txid in blockTweaks.keys) {
          final tweakData = blockTweaks[txid];
          final outputPubkeys = tweakData!.outputPubkeys;
          final tweak = tweakData.tweak;

          try {
            // scanOutputs called from rust here
            final addToWallet = {};

            receivers.forEach((receiver) {
              final scanResult = scanOutputs(outputPubkeys.keys.toList(), tweak, receiver);

              addToWallet.addAll(scanResult);
            });
            // final addToWallet = scanOutputs(
            //   outputPubkeys.keys.toList(),
            //   tweak,
            //   receivers.last,
            // );

            if (addToWallet.isEmpty) {
              // no results tx, continue to next tx
              continue;
            }

            // placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s)
            final txInfo = ElectrumTransactionInfo(
              WalletType.bitcoin,
              id: txid,
              height: tweakHeight,
              amount: 0,
              fee: 0,
              direction: TransactionDirection.incoming,
              isPending: false,
              isReplaced: false,
              // TODO: tx time mempool api
              date: scanData.network == BitcoinNetwork.mainnet
                  ? getDateByBitcoinHeight(tweakHeight)
                  : DateTime.now(),
              time: null,
              confirmations: scanData.chainTip - tweakHeight + 1,
              unspents: [],
              isReceivedSilentPayment: true,
            );

            addToWallet.forEach((label, value) {
              (value as Map<String, dynamic>).forEach((output, tweak) {
                final t_k = tweak.toString();

                final receivingOutputAddress = ECPublic.fromHex(output)
                    .toTaprootAddress(tweak: false)
                    .toAddress(scanData.network);

                final matchingOutput = outputPubkeys[output]!;
                final amount = matchingOutput.amount;
                final pos = matchingOutput.vout;

                final receivedAddressRecord = BitcoinReceivedSPAddressRecord(
                  receivingOutputAddress,
                  labelIndex: 1, // TODO: get actual index/label
                  isUsed: true,
                  spendKey: scanData.silentPaymentsWallets.first.b_spend.tweakAdd(
                    BigintUtils.fromBytes(BytesUtils.fromHexString(t_k)),
                  ),
                  txCount: 1,
                  balance: amount,
                );

                final unspent = BitcoinUnspent(receivedAddressRecord, txid, amount, pos);

                txInfo.unspents!.add(unspent);
                txInfo.amount += unspent.value;
              });
            });

            _sendResponse(ElectrumWorkerTweaksSubscribeResponse(
              result: TweaksSyncResponse(transactions: {txInfo.id: txInfo}),
            ));

            return;
          } catch (e, stacktrace) {
            print(stacktrace);
            print(e.toString());
          }
        }
      } catch (e, stacktrace) {
        print(stacktrace);
        print(e.toString());
      }

      syncHeight = tweakHeight;

      if (tweakHeight >= scanData.chainTip || scanData.isSingleScan) {
        _sendResponse(
          ElectrumWorkerTweaksSubscribeResponse(
            result: TweaksSyncResponse(
              height: syncHeight,
              syncStatus: scanData.isSingleScan
                  ? SyncedSyncStatus()
                  : SyncedTipSyncStatus(scanData.chainTip),
            ),
          ),
        );

        stream?.close();
        return;
      }
    }

    stream?.listen((event) => listenFn(event, req));
    _isScanning = false;
  }

  Future<void> _handleGetVersion(ElectrumWorkerGetVersionRequest request) async {
    _sendResponse(ElectrumWorkerGetVersionResponse(
        result: (await _electrumClient!.request(
          ElectrumVersion(
            clientName: "",
            protocolVersion: ["1.4"],
          ),
        )),
        id: request.id));
  }
}

Future<void> delegatedScan(ScanData scanData) async {
  // int syncHeight = scanData.height;
  // int initialSyncHeight = syncHeight;

  // BehaviorSubject<Object>? tweaksSubscription = null;

  // final electrumClient = scanData.electrumClient;
  // await electrumClient.connectToUri(
  //   scanData.node?.uri ?? Uri.parse("tcp://electrs.cakewallet.com:50001"),
  //   useSSL: scanData.node?.useSSL ?? false,
  // );

  // if (tweaksSubscription == null) {
  //   scanData.sendPort.send(SyncResponse(syncHeight, StartingScanSyncStatus(syncHeight)));

  //   tweaksSubscription = await electrumClient.tweaksScan(
  //     pubSpendKey: scanData.silentAddress.B_spend.toHex(),
  //   );

  //   Future<void> listenFn(t) async {
  //     final tweaks = t as Map<String, dynamic>;
  //     final msg = tweaks["message"];

  //     // success or error msg
  //     final noData = msg != null;
  //     if (noData) {
  //       return;
  //     }

  //     // Continuous status UI update, send how many blocks left to scan
  //     final syncingStatus = scanData.isSingleScan
  //         ? SyncingSyncStatus(1, 0)
  //         : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, syncHeight);
  //     scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

  //     final blockHeight = tweaks.keys.first;
  //     final tweakHeight = int.parse(blockHeight);

  //     try {
  //       final blockTweaks = tweaks[blockHeight] as Map<String, dynamic>;

  //       for (var j = 0; j < blockTweaks.keys.length; j++) {
  //         final txid = blockTweaks.keys.elementAt(j);
  //         final details = blockTweaks[txid] as Map<String, dynamic>;
  //         final outputPubkeys = (details["output_pubkeys"] as Map<dynamic, dynamic>);
  //         final spendingKey = details["spending_key"].toString();

  //         try {
  //           // placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s)
  //           final txInfo = ElectrumTransactionInfo(
  //             WalletType.bitcoin,
  //             id: txid,
  //             height: tweakHeight,
  //             amount: 0,
  //             fee: 0,
  //             direction: TransactionDirection.incoming,
  //             isPending: false,
  //             isReplaced: false,
  //             date: scanData.network == BitcoinNetwork.mainnet
  //                 ? getDateByBitcoinHeight(tweakHeight)
  //                 : DateTime.now(),
  //             confirmations: scanData.chainTip - tweakHeight + 1,
  //             unspents: [],
  //             isReceivedSilentPayment: true,
  //           );

  //           outputPubkeys.forEach((pos, value) {
  //             final secKey = ECPrivate.fromHex(spendingKey);
  //             final receivingOutputAddress =
  //                 secKey.getPublic().toTaprootAddress(tweak: false).toAddress(scanData.network);

  //             late int amount;
  //             try {
  //               amount = int.parse(value[1].toString());
  //             } catch (_) {
  //               return;
  //             }

  //             final receivedAddressRecord = BitcoinReceivedSPAddressRecord(
  //               receivingOutputAddress,
  //               labelIndex: 0,
  //               isUsed: true,
  //               spendKey: secKey,
  //               txCount: 1,
  //               balance: amount,
  //             );

  //             final unspent = BitcoinUnspent(
  //               receivedAddressRecord,
  //               txid,
  //               amount,
  //               int.parse(pos.toString()),
  //             );

  //             txInfo.unspents!.add(unspent);
  //             txInfo.amount += unspent.value;
  //           });

  //           scanData.sendPort.send({txInfo.id: txInfo});
  //         } catch (_) {}
  //       }
  //     } catch (_) {}

  //     syncHeight = tweakHeight;

  //     if (tweakHeight >= scanData.chainTip || scanData.isSingleScan) {
  //       if (tweakHeight >= scanData.chainTip)
  //         scanData.sendPort.send(SyncResponse(
  //           syncHeight,
  //           SyncedTipSyncStatus(scanData.chainTip),
  //         ));

  //       if (scanData.isSingleScan) {
  //         scanData.sendPort.send(SyncResponse(syncHeight, SyncedSyncStatus()));
  //       }

  //       await tweaksSubscription!.close();
  //       await electrumClient.close();
  //     }
  //   }

  //   tweaksSubscription?.listen(listenFn);
  // }

  // if (tweaksSubscription == null) {
  //   return scanData.sendPort.send(
  //     SyncResponse(syncHeight, UnsupportedSyncStatus()),
  //   );
  // }
}

class ScanNode {
  final Uri uri;
  final bool? useSSL;

  ScanNode(this.uri, this.useSSL);
}
