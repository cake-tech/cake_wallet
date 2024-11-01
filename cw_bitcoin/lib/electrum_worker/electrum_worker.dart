import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_methods.dart';
// import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_worker/electrum_worker_params.dart';
import 'package:cw_bitcoin/electrum_worker/methods/methods.dart';
import 'package:http/http.dart' as http;

// TODO: ping

class ElectrumWorker {
  final SendPort sendPort;
  ElectrumApiProvider? _electrumClient;

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
    print("Worker: received message: $message");

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
        case ElectrumRequestMethods.headersSubscribeMethod:
          await _handleHeadersSubscribe();
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
        case 'blockchain.scripthash.listunspent':
          // await _handleListUnspent(workerMessage);
          break;
        // Add other method handlers here
        // default:
        //   _sendError(workerMethod, 'Unsupported method: ${workerMessage.method}');
      }
    } catch (e, s) {
      print(s);
      _sendError(ElectrumWorkerErrorResponse(error: e.toString()));
    }
  }

  Future<void> _handleConnect(ElectrumWorkerConnectionRequest request) async {
    _electrumClient = ElectrumApiProvider(
      await ElectrumTCPService.connect(
        request.uri,
        onConnectionStatusChange: (status) {
          _sendResponse(ElectrumWorkerConnectionResponse(status: status));
        },
        defaultRequestTimeOut: const Duration(seconds: 5),
        connectionTimeOut: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleHeadersSubscribe() async {
    final listener = _electrumClient!.subscribe(ElectrumHeaderSubscribe());
    if (listener == null) {
      _sendError(ElectrumWorkerHeadersSubscribeError(error: 'Failed to subscribe'));
      return;
    }

    listener((event) {
      _sendResponse(ElectrumWorkerHeadersSubscribeResponse(result: event));
    });
  }

  Future<void> _handleScriphashesSubscribe(
    ElectrumWorkerScripthashesSubscribeRequest request,
  ) async {
    await Future.wait(request.scripthashByAddress.entries.map((entry) async {
      final address = entry.key;
      final scripthash = entry.value;

      final listener = await _electrumClient!.subscribe(
        ElectrumScriptHashSubscribe(scriptHash: scripthash),
      );

      if (listener == null) {
        _sendError(ElectrumWorkerScripthashesSubscribeError(error: 'Failed to subscribe'));
        return;
      }

      // https://electrumx.readthedocs.io/en/latest/protocol-basics.html#status
      // The status of the script hash is the hash of the tx history, or null if the string is empty because there are no transactions
      listener((status) async {
        print("status: $status");

        _sendResponse(ElectrumWorkerScripthashesSubscribeResponse(
          result: {address: status},
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
          late ElectrumTransactionInfo tx;

          try {
            // Exception thrown on null
            tx = result.storedTxs.firstWhere((tx) => tx.id == txid);

            if (height > 0) {
              tx.height = height;

              // the tx's block itself is the first confirmation so add 1
              tx.confirmations = result.chainTip - height + 1;
              tx.isPending = tx.confirmations == 0;
            }
          } catch (_) {
            tx = ElectrumTransactionInfo.fromElectrumBundle(
              await getTransactionExpanded(
                hash: txid,
                currentChainTip: result.chainTip,
                mempoolAPIEnabled: result.mempoolAPIEnabled,
              ),
              result.walletType,
              result.network,
              addresses: result.addresses.map((addr) => addr.address).toSet(),
              height: height,
            );
          }

          final addressHistories = histories[addressRecord.address];
          if (addressHistories != null) {
            addressHistories.txs.add(tx);
          } else {
            histories[addressRecord.address] = AddressHistoriesResponse(
              addressRecord: addressRecord,
              txs: [tx],
              walletType: result.walletType,
            );
          }

          return Future.value(null);
        }));
      }

      return histories;
    }));

    _sendResponse(ElectrumWorkerGetHistoryResponse(result: histories.values.toList()));
  }

  Future<ElectrumTransactionBundle> getTransactionExpanded({
    required String hash,
    required int currentChainTip,
    required bool mempoolAPIEnabled,
    bool getConfirmations = true,
  }) async {
    int? time;
    int? height;
    int? confirmations;

    final transactionHex = await _electrumClient!.request(
      ElectrumGetTransactionHex(transactionHash: hash),
    );

    if (getConfirmations) {
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

            if (blockHash.statusCode == 200 &&
                blockHash.body.isNotEmpty &&
                jsonDecode(blockHash.body) != null) {
              final blockResponse = await http.get(
                Uri.parse(
                  "http://mempool.cakewallet.com:8999/api/v1/block/${blockHash.body}",
                ),
              );

              if (blockResponse.statusCode == 200 &&
                  blockResponse.body.isNotEmpty &&
                  jsonDecode(blockResponse.body)['timestamp'] != null) {
                time = int.parse(jsonDecode(blockResponse.body)['timestamp'].toString());
              }
            }
          }
        } catch (_) {}
      }

      if (height != null) {
        if (time == null && height > 0) {
          time = (getDateByBitcoinHeight(height).millisecondsSinceEpoch / 1000).round();
        }

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
        ElectrumGetTransactionHex(transactionHash: vin.txId),
      );

      ins.add(BtcTransaction.fromRaw(inputTransactionHex));
    }

    return ElectrumTransactionBundle(
      original,
      ins: ins,
      time: time,
      confirmations: confirmations ?? 0,
    );
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

    _sendResponse(ElectrumWorkerGetBalanceResponse(
      result: ElectrumBalance(
        confirmed: totalConfirmed,
        unconfirmed: totalUnconfirmed,
        frozen: 0,
      ),
    ));
  }
}
