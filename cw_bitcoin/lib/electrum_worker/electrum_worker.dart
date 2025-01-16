import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cw_core/get_height_by_date.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_methods.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_params.dart';
import 'package:cw_bitcoin/electrum_worker/methods/methods.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sp_scanner/sp_scanner.dart';

class ElectrumWorker {
  final SendPort sendPort;
  ElectrumProvider? _electrumClient;
  BehaviorSubject<Map<String, dynamic>>? _scanningStream;

  BasedUtxoNetwork? _network;
  WalletType? _walletType;

  ElectrumWorker._(this.sendPort, {ElectrumProvider? electrumClient})
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
    // printV("Worker: received message: $message");

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
        case ElectrumRequestMethods.tweaksSubscribeMethod:
          await _handleScanSilentPayments(
            ElectrumWorkerTweaksSubscribeRequest.fromJson(messageJson),
          );

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
    _walletType = request.walletType;

    try {
      _electrumClient = await ElectrumProvider.connect(
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
    final req = ElectrumRequestHeaderSubscribe();

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
      final scripthash = entry.value.toString();

      final req = ElectrumRequestScriptHashSubscribe(scriptHash: scripthash);

      final stream = await _electrumClient!.subscribe(req);

      if (stream == null) {
        _sendError(ElectrumWorkerScripthashesSubscribeError(error: 'Failed to subscribe'));
        return;
      }

      // https://electrumx.readthedocs.io/en/latest/protocol-basics.html#status
      // The status of the script hash is the hash of the tx history, or null if the string is empty because there are no transactions
      stream.listen((status) async {
        if (status == null) {
          return;
        }

        printV("status: $status");

        _sendResponse(ElectrumWorkerScripthashesSubscribeResponse(
          result: {address: req.onResponse(status)},
          id: request.id,
        ));
      });
    }));
  }

  Future<void> _handleGetInitialHistory(ElectrumWorkerGetHistoryRequest request) async {
    var histories = <String, AddressHistoriesResponse>{};
    final scripthashes = <String>[];
    final addresses = <String>[];
    request.addresses.forEach((addr) {
      addr.txCount = 0;

      if (addr.scriptHash.isNotEmpty) {
        scripthashes.add(addr.scriptHash);
        addresses.add(addr.address);
      }
    });

    final historyBatches = await _electrumClient!.batchRequest(
      ElectrumBatchRequestScriptHashGetHistory(
        scriptHashes: scripthashes,
      ),
    );

    final transactionIdsForHeights = <String, int>{};

    for (final batch in historyBatches) {
      final history = batch.result;
      if (history.isEmpty) {
        continue;
      }

      history.forEach((tx) {
        transactionIdsForHeights[tx['tx_hash'] as String] = tx['height'] as int;
      });
    }

    if (transactionIdsForHeights.isNotEmpty) {
      final transactions = await _getInitialBatchTransactionsExpanded(
        hashesForHeights: transactionIdsForHeights,
        currentChainTip: request.chainTip,
      );

      transactions.forEach((tx) {
        final txInfo = ElectrumTransactionInfo.fromElectrumBundle(
          tx,
          request.walletType,
          request.network,
          addresses: addresses.toSet(),
          // height: height,
        );

        request.addresses.forEach(
          (addr) {
            final usedAddress = (txInfo.outputAddresses?.contains(addr.address) ?? false) ||
                (txInfo.inputAddresses?.contains(addr.address) ?? false);
            if (usedAddress == true) {
              addr.setAsUsed();
              addr.txCount++;

              final addressHistories = histories[addr.address];
              if (addressHistories != null) {
                addressHistories.txs.add(txInfo);
              } else {
                histories[addr.address] = AddressHistoriesResponse(
                  addressRecord: addr,
                  txs: [txInfo],
                  walletType: request.walletType,
                );
              }
            }
          },
        );
      });

      if (histories.isNotEmpty) {
        _sendResponse(
          ElectrumWorkerGetHistoryResponse(
            result: histories.values.toList(),
            id: request.id,
          ),
        );
      }
    }
  }

  Future<void> _handleGetHistory(ElectrumWorkerGetHistoryRequest request) async {
    if (request.storedTxs.isEmpty) {
      return await _handleGetInitialHistory(request);
    }

    var histories = <String, AddressHistoriesResponse>{};
    final scripthashes = <String>[];
    final addresses = <String>[];
    request.addresses.forEach((addr) {
      addr.txCount = 0;

      if (addr.scriptHash.isNotEmpty) {
        scripthashes.add(addr.scriptHash);
        addresses.add(addr.address);
      }
    });

    final historyBatches = await _electrumClient!.batchRequest(
      ElectrumBatchRequestScriptHashGetHistory(
        scriptHashes: scripthashes,
      ),
    );

    final transactionIdsHeights = <String, TxToFetch>{};

    await Future.wait(historyBatches.map((result) async {
      final history = result.result;
      if (history.isEmpty) {
        return;
      }

      for (final transaction in history) {
        final txid = transaction['tx_hash'] as String;
        final height = transaction['height'] as int;
        ElectrumTransactionInfo? tx;

        try {
          // Exception thrown if non existing, handled on null condition below trycatch
          tx = request.storedTxs.firstWhere((tx) => tx.id == txid);

          if (height > 0) {
            tx.height = height;

            // the tx's block itself is the first confirmation so add 1
            tx.confirmations = request.chainTip - height + 1;
            tx.isPending = tx.confirmations == 0;
          }
        } catch (_) {}

        // date is validated when the API responds with the same date at least twice
        // since sometimes the mempool api returns the wrong date at first, and we update
        if (tx == null || (tx.isDateValidated != true && request.mempoolAPIEnabled)) {
          transactionIdsHeights[txid] = TxToFetch(height: height, tx: tx);
        }
      }
    }));

    final txInfos = [...request.storedTxs];

    if (transactionIdsHeights.isNotEmpty) {
      final transactions = await _getBatchTransactionsExpanded(
        txsForHeights: transactionIdsHeights,
        currentChainTip: request.chainTip,
        mempoolAPIEnabled: request.mempoolAPIEnabled,
        getTime: true,
      );

      transactions.entries.forEach((result) {
        final hash = result.key;
        final txBundle = result.value;

        final txInfo = ElectrumTransactionInfo.fromElectrumBundle(
          txBundle,
          request.walletType,
          request.network,
          addresses: addresses.toSet(),
          height: transactionIdsHeights[hash]?.height,
        );

        txInfos.add(txInfo);
      });
    }

    txInfos.forEach((txInfo) {
      request.addresses.forEach(
        (addr) {
          final usedAddress = (txInfo.outputAddresses?.contains(addr.address) ?? false) ||
              (txInfo.inputAddresses?.contains(addr.address) ?? false);

          if (usedAddress == true) {
            addr.setAsUsed();
            addr.txCount++;

            final addressHistories = histories[addr.address];
            if (addressHistories != null) {
              addressHistories.txs.add(txInfo);
            } else {
              histories[addr.address] = AddressHistoriesResponse(
                addressRecord: addr,
                txs: [txInfo],
                walletType: request.walletType,
              );
            }
          }
        },
      );
    });

    if (histories.isNotEmpty) {
      _sendResponse(
        ElectrumWorkerGetHistoryResponse(
          result: histories.values.toList(),
          id: request.id,
        ),
      );
    }
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
    final balances = await _electrumClient!.batchRequest(
      ElectrumBatchRequestGetScriptHashBalance(
        scriptHashes: request.scripthashes.where((s) => s.isNotEmpty).toList(),
      ),
    );

    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    for (final result in balances) {
      final balance = result.result;
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
      if (scriptHash.isEmpty) {
        return;
      }

      final scriptHashUnspents = await _electrumClient!
          .request(
            ElectrumRequestScriptHashListUnspent(scriptHash: scriptHash),
          )
          .timeout(const Duration(seconds: 3));

      if (scriptHashUnspents.isNotEmpty) {
        unspents[scriptHash] = scriptHashUnspents;
      }
    }));

    _sendResponse(ElectrumWorkerListUnspentResponse(utxos: unspents, id: request.id));
  }

  Future<void> _handleBroadcast(ElectrumWorkerBroadcastRequest request) async {
    final rpcId = _electrumClient!.id + 1;
    final txHash = await _electrumClient!.request(
      ElectrumRequestBroadCastTransaction(transactionRaw: request.transactionRaw),
    );

    if (txHash == null) {
      final error = (_electrumClient!.rpc as ElectrumSSLService).getError(rpcId);

      if (error?.message != null) {
        return _sendError(ElectrumWorkerBroadcastError(error: error!.message, id: request.id));
      }
    } else {
      _sendResponse(ElectrumWorkerBroadcastResponse(txHash: txHash, id: request.id));
    }
  }

  Future<void> _handleGetTxExpanded(ElectrumWorkerTxExpandedRequest request) async {
    final tx = await _getTransactionExpanded(
      hash: request.txHash,
      currentChainTip: request.currentChainTip,
      mempoolAPIEnabled: false,
    );

    _sendResponse(ElectrumWorkerTxExpandedResponse(expandedTx: tx, id: request.id));
  }

  Future<List<ElectrumTransactionBundle>> _getInitialBatchTransactionsExpanded({
    required Map<String, int> hashesForHeights,
    required int currentChainTip,
  }) async {
    final hashes = hashesForHeights.keys.toList();

    final transactionVerboseBatches = await _electrumClient!.batchRequest(
      ElectrumBatchRequestGetTransactionVerbose(transactionHashes: hashes),
    );
    List<String> transactionHexes = [];
    List<String> emptyVerboseTxs = [];

    transactionVerboseBatches.forEach((batch) {
      final txVerbose = batch.result;
      if (txVerbose.isEmpty) {
        emptyVerboseTxs.add(
          (batch.request.paramsById[batch.id] as List<dynamic>).first as String,
        );
      } else {
        transactionHexes.add(txVerbose['hex'] as String);
      }
    });

    if (emptyVerboseTxs.isNotEmpty) {
      transactionHexes.addAll((await _electrumClient!.batchRequest(
        ElectrumBatchRequestGetTransactionHex(transactionHashes: hashes),
      ))
          .map((result) => result.result)
          .toList());
    }

    final dates = <String, DateTime>{};

    if (_walletType == WalletType.bitcoin) {
      for (final hash in hashes) {
        try {
          final date = getDateByBitcoinHeight(hashesForHeights[hash]!);
          dates[hash] = date;
        } catch (_) {}
      }
    }

    final bundles = <ElectrumTransactionBundle>[];
    final insHashes = <String>[];

    for (final txHex in transactionHexes) {
      final original = BtcTransaction.fromRaw(txHex);
      insHashes.addAll(original.inputs.map((e) => e.txId));
    }

    final inputTransactionHexBatches = await _electrumClient!.batchRequest(
      ElectrumBatchRequestGetTransactionHex(
        transactionHashes: insHashes,
      ),
    );

    for (final txHex in transactionHexes) {
      final original = BtcTransaction.fromRaw(txHex);
      final ins = <BtcTransaction>[];

      for (final input in original.inputs) {
        try {
          final inputTransactionHex = inputTransactionHexBatches
              .firstWhere(
                (batch) =>
                    (batch.request.paramsById[batch.id] as List<dynamic>).first == input.txId,
              )
              .result;

          ins.add(BtcTransaction.fromRaw(inputTransactionHex));
        } catch (_) {}
      }

      final date = dates[original.txId];
      final height = hashesForHeights[original.txId] ?? 0;
      final tip = currentChainTip;

      bundles.add(
        ElectrumTransactionBundle(
          original,
          ins: ins,
          time: date?.millisecondsSinceEpoch,
          confirmations: tip - height + 1,
        ),
      );
    }

    return bundles;
  }

  Future<Map<String, ElectrumTransactionBundle>> _getBatchTransactionsExpanded({
    required Map<String, TxToFetch> txsForHeights,
    required int currentChainTip,
    required bool mempoolAPIEnabled,
    bool getTime = false,
  }) async {
    final hashes = txsForHeights.keys.toList();

    final transactionVerboseBatches = await _electrumClient!.batchRequest(
      ElectrumBatchRequestGetTransactionVerbose(transactionHashes: hashes),
    );
    List<String> transactionHexes = [];
    List<String> emptyVerboseTxs = [];

    transactionVerboseBatches.forEach((batch) {
      final txVerbose = batch.result;
      if (txVerbose.isEmpty) {
        emptyVerboseTxs.add(
          (batch.request.paramsById[batch.id] as List<dynamic>).first as String,
        );
      } else {
        transactionHexes.add(txVerbose['hex'] as String);
      }
    });

    if (emptyVerboseTxs.isNotEmpty) {
      transactionHexes.addAll((await _electrumClient!.batchRequest(
        ElectrumBatchRequestGetTransactionHex(transactionHashes: hashes),
      ))
          .map((result) => result.result)
          .toList());
    }

    final datesByHashes = <String, DateResult>{};

    if (_walletType == WalletType.bitcoin) {
      await Future.wait(hashes.map((hash) async {
        try {
          if (getTime && _walletType == WalletType.bitcoin && mempoolAPIEnabled) {
            final tx = txsForHeights[hash]?.tx;

            try {
              final dates = await getTxDate(
                hash,
                _network!,
                currentChainTip,
                date: tx?.date,
                confirmations: tx?.confirmations,
              );
              datesByHashes[hash] = dates;
            } catch (_) {}
          }
        } catch (_) {}
      }));
    }

    final bundles = <String, ElectrumTransactionBundle>{};
    final insHashes = <String>[];

    for (final txHex in transactionHexes) {
      final original = BtcTransaction.fromRaw(txHex);
      insHashes.addAll(original.inputs.map((e) => e.txId));
    }

    final inputTransactionHexBatches = await _electrumClient!.batchRequest(
      ElectrumBatchRequestGetTransactionHex(
        transactionHashes: insHashes,
      ),
    );

    for (final txHex in transactionHexes) {
      final original = BtcTransaction.fromRaw(txHex);
      final ins = <BtcTransaction>[];

      for (final input in original.inputs) {
        try {
          final inputTransactionHex = inputTransactionHexBatches
              .firstWhere(
                (batch) =>
                    (batch.request.paramsById[batch.id] as List<dynamic>).first == input.txId,
              )
              .result;

          ins.add(BtcTransaction.fromRaw(inputTransactionHex));
        } catch (_) {}
      }

      final dates = datesByHashes[original.txId()];

      bundles[original.txId()] = ElectrumTransactionBundle(
        original,
        ins: ins,
        time: dates?.time,
        confirmations: dates?.confirmations ?? 0,
        isDateValidated: dates?.isDateValidated,
      );
    }

    return bundles;
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
    DateResult? dates;

    final transactionVerbose = await _electrumClient!.request(
      ElectrumRequestGetTransactionVerbose(transactionHash: hash),
    );
    String transactionHex;

    if (transactionVerbose.isNotEmpty) {
      transactionHex = transactionVerbose['hex'] as String;
      time = transactionVerbose['time'] as int?;
      confirmations = transactionVerbose['confirmations'] as int?;
    } else {
      transactionHex = await _electrumClient!.request(
        ElectrumRequestGetTransactionHex(transactionHash: hash),
      );
    }

    if (getTime && _walletType == WalletType.bitcoin) {
      if (mempoolAPIEnabled) {
        try {
          dates = await getTxDate(
            hash,
            _network!,
            currentChainTip,
            confirmations: confirmations,
            date: date,
          );
        } catch (_) {}
      }
    }

    final original = BtcTransaction.fromRaw(transactionHex);
    final ins = <BtcTransaction>[];

    for (final vin in original.inputs) {
      final inputTransactionHex = await _electrumClient!.request(
        // TODO: _getTXHex
        ElectrumRequestGetTransactionHex(transactionHash: vin.txId),
      );

      ins.add(BtcTransaction.fromRaw(inputTransactionHex));
    }

    return ElectrumTransactionBundle(
      original,
      ins: ins,
      time: time ?? dates?.time,
      confirmations: confirmations ?? dates?.confirmations ?? 0,
      isDateValidated: dates?.isDateValidated,
    );
  }

  Future<void> _handleGetFeeRates(ElectrumWorkerGetFeesRequest request) async {
    if (request.mempoolAPIEnabled && _walletType == WalletType.bitcoin) {
      try {
        final recommendedFees = await ApiProvider.fromMempool(
          _network!,
          baseUrl: "http://mempool.cakewallet.com:8999/api/v1",
        ).getRecommendedFeeRate();

        final minimum = recommendedFees.minimumFee!.satoshis;
        final economy = recommendedFees.economyFee!.satoshis;
        final hour = recommendedFees.low.satoshis;
        int halfHour = recommendedFees.medium.satoshis;
        int fastest = recommendedFees.high.satoshis;

        // Bitcoin only: adjust fee rates to avoid equal fee values
        // elevated fee should be higher than normal fee
        if (hour == halfHour) {
          halfHour++;
        }
        // priority fee should be higher than elevated fee
        while (fastest <= halfHour) {
          fastest++;
        }
        // this guarantees that, even if all fees are low and equal,
        // higher priority fee txs can be consumed when chain fees start surging

        _sendResponse(
          ElectrumWorkerGetFeesResponse(
            result: BitcoinAPITransactionPriorities(
              minimum: minimum,
              economy: economy,
              hour: hour,
              halfHour: halfHour,
              fastest: fastest,
              custom: minimum,
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
    _scanningStream?.close();
    _scanningStream = null;
    _sendResponse(
      ElectrumWorkerStopScanningResponse(result: true, id: request.id),
    );
  }

  Future<void> _handleScanSilentPayments(ElectrumWorkerTweaksSubscribeRequest request) async {
    final scanData = request.scanData;

    var scanningClient = _electrumClient;

    if (scanData.shouldSwitchNodes) {
      scanningClient = await ElectrumProvider.connect(
        ElectrumTCPService.connect(
          // TODO: ssl
          Uri.parse("tcp://electrs.cakewallet.com:50001"),
        ),
      );
    }
    int syncHeight = scanData.height;
    int initialSyncHeight = syncHeight;

    final receivers = scanData.silentPaymentsWallets.map(
      (wallet) => Receiver(
        wallet.b_scan.toHex(),
        wallet.B_spend.toHex(),
        scanData.network == BitcoinNetwork.testnet,
        scanData.labelIndexes,
      ),
    );

    int getCountPerRequest(int syncHeight) {
      if (scanData.isSingleScan) {
        return 1;
      }

      final amountLeft = scanData.chainTip - syncHeight + 1;
      return amountLeft;
    }

    // Initial status UI update, send how many blocks in total to scan
    // TODO: isSingleScan : dont update restoreHeight
    _sendResponse(ElectrumWorkerTweaksSubscribeResponse(
      result: TweaksSyncResponse(
        height: syncHeight,
        syncStatus: StartingScanSyncStatus(syncHeight),
      ),
    ));

    final req = ElectrumTweaksSubscribe(
      height: syncHeight,
      count: getCountPerRequest(syncHeight),
      historicalMode: false,
    );

    _scanningStream = await scanningClient!.subscribe(req);

    void listenFn(Map<String, dynamic> event, ElectrumTweaksSubscribe req) async {
      final response = req.onResponse(event);

      if (response == null || _scanningStream == null) {
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
          final nextStream = scanningClient!.subscribe(
            ElectrumTweaksSubscribe(
              height: nextHeight,
              count: getCountPerRequest(nextHeight),
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
            final addToWallet = {};

            receivers.forEach((receiver) {
              // scanOutputs called from rust here
              final scanResult = scanOutputs(outputPubkeys.keys.toList(), tweak, receiver);

              if (scanResult.isEmpty) {
                return;
              }

              if (addToWallet[receiver.BSpend] == null) {
                addToWallet[receiver.BSpend] = scanResult;
              } else {
                addToWallet[receiver.BSpend].addAll(scanResult);
              }
            });

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
              date: DateTime.fromMillisecondsSinceEpoch(
                (await getTxDate(
                      txid,
                      scanData.network,
                      scanData.chainTip,
                    ))
                        .time! *
                    1000,
              ),
              confirmations: scanData.chainTip - tweakHeight + 1,
              isReceivedSilentPayment: true,
            );

            List<BitcoinUnspent> unspents = [];

            addToWallet.forEach((BSpend, result) {
              result.forEach((label, value) {
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
                    isChange: false, // and if change or not
                    isUsed: true,
                    tweak: t_k,
                    txCount: 1,
                    balance: amount,
                  );

                  final unspent = BitcoinUnspent(receivedAddressRecord, txid, amount, pos);

                  unspents.add(unspent);
                  txInfo.amount += unspent.value;
                });
              });
            });

            _sendResponse(ElectrumWorkerTweaksSubscribeResponse(
              result: TweaksSyncResponse(
                transactions: {txInfo.id: TweakResponseData(txInfo: txInfo, unspents: unspents)},
              ),
            ));

            return;
          } catch (e, stacktrace) {
            printV(stacktrace);
            printV(e.toString());
          }
        }
      } catch (e, stacktrace) {
        printV(stacktrace);
        printV(e.toString());
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

        _scanningStream?.close();
        _scanningStream = null;
        return;
      }
    }

    _scanningStream?.listen((event) => listenFn(event, req));
  }

  Future<void> _handleGetVersion(ElectrumWorkerGetVersionRequest request) async {
    _sendResponse(
      ElectrumWorkerGetVersionResponse(
        result: await _electrumClient!.request(
          ElectrumRequestVersion(
            clientName: "",
            protocolVersion: "1.4",
          ),
        ),
        id: request.id,
      ),
    );
  }
}

class ScanNode {
  final Uri uri;
  final bool? useSSL;

  ScanNode(this.uri, this.useSSL);
}

class DateResult {
  final int? time;
  final int? height;
  final int? confirmations;
  final bool? isDateValidated;

  DateResult({
    this.time,
    this.height,
    this.isDateValidated,
    this.confirmations,
  });
}

Future<DateResult> getTxDate(
  String txid,
  BasedUtxoNetwork network,
  int currentChainTip, {
  int? confirmations,
  DateTime? date,
}) async {
  int? time;
  int? height;
  bool? isDateValidated;

  final mempoolApi = ApiProvider.fromMempool(
    network,
    baseUrl: "http://mempool.cakewallet.com:8999/api/v1",
  );

  try {
    final txVerbose = await mempoolApi.getTransaction<MempoolTransaction>(txid);

    final status = txVerbose.status;
    height = status.blockHeight;

    if (height != null) {
      final blockHash = await mempoolApi.getBlockHeight(height);
      final block = await mempoolApi.getBlock(blockHash);

      time = int.parse(block['timestamp'].toString());

      if (date != null) {
        final newDate = DateTime.fromMillisecondsSinceEpoch(time * 1000);
        isDateValidated = newDate == date;
      }
    }
  } catch (_) {}

  if (confirmations == null && height != null) {
    final tip = currentChainTip;
    if (tip > 0 && height > 0) {
      // Add one because the block itself is the first confirmation
      confirmations = tip - height + 1;
    }
  }

  return DateResult(
    time: time,
    height: height,
    isDateValidated: isDateValidated,
    confirmations: confirmations,
  );
}

class TxToFetch {
  final ElectrumTransactionInfo? tx;
  final int height;

  TxToFetch({required this.height, this.tx});
}
