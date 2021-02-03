import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/bitcoin/file.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';

part 'bitcoin_transaction_history.g.dart';

const _transactionsHistoryFileName = 'transactions.json';

class BitcoinTransactionHistory = BitcoinTransactionHistoryBase
    with _$BitcoinTransactionHistory;

abstract class BitcoinTransactionHistoryBase
    extends TransactionHistoryBase<BitcoinTransactionInfo> with Store {
  BitcoinTransactionHistoryBase(
      {this.eclient, String dirPath, @required String password})
      : path = '$dirPath/$_transactionsHistoryFileName',
        _password = password,
        _height = 0,
        _isUpdating = false {
    transactions = ObservableMap<String, BitcoinTransactionInfo>();
  }

  BitcoinWalletBase wallet;
  final ElectrumClient eclient;
  final String path;
  final String _password;
  int _height;
  bool _isUpdating;

  Future<void> init() async {
    await _load();
  }

  @override
  Future update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      final txs = await fetchTransactions();
      await add(txs);
      _isUpdating = false;
    } catch (_) {
      _isUpdating = false;
      rethrow;
    }
  }

  @override
  Future<Map<String, BitcoinTransactionInfo>> fetchTransactions() async {
    final histories =
        wallet.scriptHashes.map((scriptHash) => eclient.getHistory(scriptHash));
    final _historiesWithDetails = await Future.wait(histories)
        .then((histories) => histories.expand((i) => i).toList())
        .then((histories) => histories.map((tx) => fetchTransactionInfo(
            hash: tx['tx_hash'] as String, height: tx['height'] as int)));
    final historiesWithDetails = await Future.wait(_historiesWithDetails);

    return historiesWithDetails.fold<Map<String, BitcoinTransactionInfo>>(
        <String, BitcoinTransactionInfo>{}, (acc, tx) {
      acc[tx.id] = acc[tx.id]?.updated(tx) ?? tx;
      return acc;
    });
  }

  Future<BitcoinTransactionInfo> fetchTransactionInfo(
      {@required String hash, @required int height}) async {
    final tx = await eclient.getTransactionExpanded(hash: hash);
    return BitcoinTransactionInfo.fromElectrumVerbose(tx,
        height: height, addresses: wallet.addresses);
  }

  Future<void> add(Map<String, BitcoinTransactionInfo> transactionsList) async {
    transactionsList.entries.forEach((entry) {
      _updateOrInsert(entry.value);

      if (entry.value.height > _height) {
        _height = entry.value.height;
      }
    });

    await save();
  }

  Future<void> addOne(BitcoinTransactionInfo tx) async {
    _updateOrInsert(tx);

    if (tx.height > _height) {
      _height = tx.height;
    }

    await save();
  }

  BitcoinTransactionInfo get(String id) => transactions[id];

  Future<void> save() async {
    try {
      final data = json.encode({'height': _height, 'transactions': transactions});
      await writeData(path: path, password: _password, data: data);
    } catch(e) {
      print('Error while save bitcoin transaction history: ${e.toString()}');
    }
  }

  @override
  void updateAsync({void Function() onFinished}) {
    fetchTransactionsAsync((transaction) => _updateOrInsert(transaction),
        onFinished: onFinished);
  }

  @override
  void fetchTransactionsAsync(
      void Function(BitcoinTransactionInfo transaction) onTransactionLoaded,
      {void Function() onFinished}) async {
    final histories = await Future.wait(wallet.scriptHashes
        .map((scriptHash) async => await eclient.getHistory(scriptHash)));
    final transactionsCount =
        histories.fold<int>(0, (acc, m) => acc + m.length);
    var counter = 0;

    final batches = histories.map((metaList) =>
        _fetchBatchOfTransactions(metaList, onTransactionLoaded: (transaction) {
          onTransactionLoaded(transaction);
          counter += 1;

          if (counter == transactionsCount) {
            onFinished?.call();
          }
        }));

    await Future.wait(batches);
  }

  Future<void> _fetchBatchOfTransactions(
          Iterable<Map<String, dynamic>> metaList,
          {void Function(BitcoinTransactionInfo tranasaction)
              onTransactionLoaded}) async =>
      metaList.forEach((txMeta) => fetchTransactionInfo(
              hash: txMeta['tx_hash'] as String,
              height: txMeta['height'] as int)
          .then((transaction) => onTransactionLoaded(transaction)));

  Future<Map<String, Object>> _read() async {
    final content = await read(path: path, password: _password);
    return json.decode(content) as Map<String, Object>;
  }

  Future<void> _load() async {
    try {
      final content = await _read();
      final txs = content['transactions'] as Map<String, Object> ?? {};

      txs.entries.forEach((entry) {
        final val = entry.value;

        if (val is Map<String, Object>) {
          final tx = BitcoinTransactionInfo.fromJson(val);
          _updateOrInsert(tx);
        }
      });

      _height = content['height'] as int;
    } catch (e) {
      print(e);
    }
  }

  void _updateOrInsert(BitcoinTransactionInfo transaction) {
    if (transaction.id == null) {
      return;
    }

    if (transactions[transaction.id] == null) {
      transactions[transaction.id] = transaction;
    } else {
      final originalTx = transactions[transaction.id];
      originalTx.confirmations = transaction.confirmations;
      originalTx.amount = transaction.amount;
      originalTx.height = transaction.height;
      originalTx.date ??= transaction.date;
      originalTx.isPending = transaction.isPending;
    }
  }
}
