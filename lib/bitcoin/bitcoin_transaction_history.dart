import 'dart:convert';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/bitcoin/file.dart';

class BitcoinTransactionHistory extends TransactionHistory {
  BitcoinTransactionHistory(
      {@required this.eclient,
      @required this.path,
      @required String password,
      @required this.wallet})
      : _transactions = BehaviorSubject<List<TransactionInfo>>.seeded([]),
        _password = password,
        _height = 0;

  final BitcoinWallet wallet;
  final ElectrumClient eclient;
  final String path;
  final String _password;
  int _height;

  @override
  Observable<List<TransactionInfo>> get transactions => _transactions.stream;
  List<TransactionInfo> get transactionsAll => _transactions.value;
  final BehaviorSubject<List<TransactionInfo>> _transactions;
  bool _isUpdating = false;

  Future<void> init() async {
    final info = await _read();
    _height = (info['height'] as int) ?? _height;
    _transactions.value = info['transactions'] as List<TransactionInfo>;
  }

  @override
  Future<List<TransactionInfo>> getAll() async => _transactions.value;

  @override
  Future update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      final newTransasctions = await fetchTransactions();
      _transactions.value = _transactions.value + newTransasctions;
      _updateHeight();
      await save();
      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  Future<Map<String, Object>> fetchTransactionInfo(
      {@required String hash, @required int height}) async {
    final rawFetching = eclient.getTransactionRaw(hash: hash);
    final headerFetching = eclient.getHeader(height: height);
    final result = await Future.wait([rawFetching, headerFetching]);
    final raw = result.first as String;
    final header = result[1] as Map<String, Object>;

    return {'raw': raw, 'header': header};
  }

  Future<List<BitcoinTransactionInfo>> fetchTransactions() async {
    final addresses = wallet.getAddresses();
    final histories =
        addresses.map((address) => eclient.getHistory(address: address));
    final _historiesWithDetails = await Future.wait(histories)
        .then((histories) => histories
            .map((h) => h.where((tx) => (tx['height'] as int) > _height))
            .expand((i) => i)
            .toList())
        .then((histories) => histories.map((tx) => fetchTransactionInfo(
            hash: tx['tx_hash'] as String, height: tx['height'] as int)));
    final historiesWithDetails = await Future.wait(_historiesWithDetails);

    return historiesWithDetails
        .map((info) => BitcoinTransactionInfo.fromHexAndHeader(
            info['raw'] as String, info['header'] as Map<String, Object>,
            addresses: addresses))
        .toList();
  }

  Future<void> add(List<BitcoinTransactionInfo> transactions) async {
    final txs = await getAll()
      ..addAll(transactions);
    await writeData(
        path: path,
        password: _password,
        data: json
            .encode(txs.map((tx) => (tx as BitcoinTransactionInfo).toJson())));
  }

  Future<void> addOne(BitcoinTransactionInfo tx) async {
    final txs = await getAll()
      ..add(tx);
    await writeData(
        path: path,
        password: _password,
        data: json
            .encode(txs.map((tx) => (tx as BitcoinTransactionInfo).toJson())));
  }

  Future<void> save() async => writeData(
      path: path,
      password: _password,
      data: json
          .encode({'height': _height, 'transactions': _transactions.value}));

  Future<Map<String, Object>> _read() async {
    try {
      final content = await read(path: path, password: _password);
      final jsoned = json.decode(content) as Map<String, Object>;
      final height = jsoned['height'] as int;
      final transactions = (jsoned['transactions'] as List<dynamic>)
          .map((dynamic row) {
            if (row is Map<String, Object>) {
              return BitcoinTransactionInfo.fromJson(row);
            }

            return null;
          })
          .where((el) => el != null)
          .toList();

      return {'transactions': transactions, 'height': height};
    } catch (_) {
      return {'transactions': List<TransactionInfo>(), 'height': 0};
    }
  }

  void _updateHeight() {
    final int newHeight = _transactions.value
        .fold(0, (acc, val) => val.height > acc ? val.height : acc);
    _height = newHeight > _height ? newHeight : _height;
  }
}
