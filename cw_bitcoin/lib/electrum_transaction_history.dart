import 'dart:convert';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_bitcoin/file.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';

part 'electrum_transaction_history.g.dart';

const _transactionsHistoryFileName = 'transactions.json';

class ElectrumTransactionHistory = ElectrumTransactionHistoryBase
    with _$ElectrumTransactionHistory;

abstract class ElectrumTransactionHistoryBase
    extends TransactionHistoryBase<ElectrumTransactionInfo> with Store {
  ElectrumTransactionHistoryBase(
      {@required this.walletInfo, @required String password})
      : _password = password,
        _height = 0 {
    transactions = ObservableMap<String, ElectrumTransactionInfo>();
  }

  final WalletInfo walletInfo;
  String _password;
  int _height;

  Future<void> init() async => await _load();

  @override
  void addOne(ElectrumTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, ElectrumTransactionInfo> transactions) =>
      transactions.forEach((_, tx) => _updateOrInsert(tx));

  @override
  Future<void> save() async {
    try {
      final dirPath =
          await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
      final path = '$dirPath/$_transactionsHistoryFileName';
      final data =
          json.encode({'height': _height, 'transactions': transactions});
      await writeData(path: path, password: _password, data: data);
    } catch (e) {
      print('Error while save bitcoin transaction history: ${e.toString()}');
    }
  }

  Future<void> changePassword(String password) async {
    _password = password;
    await save();
  }

  Future<Map<String, Object>> _read() async {
    final dirPath =
        await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
    final path = '$dirPath/$_transactionsHistoryFileName';
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
          final tx = ElectrumTransactionInfo.fromJson(val, walletInfo.type);
          _updateOrInsert(tx);
        }
      });

      _height = content['height'] as int;
    } catch (e) {
      print(e);
    }
  }

  void _updateOrInsert(ElectrumTransactionInfo transaction) {
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
