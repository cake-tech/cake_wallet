import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/transaction_history.dart';
import 'package:cake_wallet/core/bitcoin_wallet.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/bitcoin/electrum.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/bitcoin/file.dart';

part 'bitcoin_transaction_history.g.dart';

// TODO: Think about another transaction store for bitcoin transaction history..

const _transactionsHistoryFileName = 'transactions.json';

class BitcoinTransactionHistory = BitcoinTransactionHistoryBase
    with _$BitcoinTransactionHistory;

abstract class BitcoinTransactionHistoryBase
    extends TranasctionHistoryBase<BitcoinTransactionInfo> with Store {
  BitcoinTransactionHistoryBase(
      {this.eclient, String dirPath, @required String password})
      : path = '$dirPath/$_transactionsHistoryFileName',
        _password = password,
        _height = 0;

  BitcoinWallet wallet;
  final ElectrumClient eclient;
  final String path;
  final String _password;
  int _height;

  Future<void> init() async {
    // TODO: throw exeption if wallet is null;
    final info = await _read();
    _height = (info['height'] as int) ?? _height;
    transactions = info['transactions'] as List<BitcoinTransactionInfo>;
  }

  @override
  Future update() async {
    await super.update();
    _updateHeight();
  }

  @override
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

  Future<Map<String, Object>> fetchTransactionInfo(
      {@required String hash, @required int height}) async {
    final rawFetching = eclient.getTransactionRaw(hash: hash);
    final headerFetching = eclient.getHeader(height: height);
    final result = await Future.wait([rawFetching, headerFetching]);
    final raw = result.first as String;
    final header = result[1] as Map<String, Object>;

    return {'raw': raw, 'header': header};
  }

  Future<void> add(List<BitcoinTransactionInfo> transactions) async {
    this.transactions.addAll(transactions);
    await save();
  }

  Future<void> addOne(BitcoinTransactionInfo tx) async {
    transactions.add(tx);
    await save();
  }

  Future<void> save() async => writeData(
      path: path,
      password: _password,
      data: json.encode({'height': _height, 'transactions': transactions}));

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
      return {'transactions': <TransactionInfo>[], 'height': 0};
    }
  }

  void _updateHeight() {
    final newHeight = transactions.fold(
        0, (int acc, val) => val.height > acc ? val.height : acc);
    _height = newHeight > _height ? newHeight : _height;
  }
}
