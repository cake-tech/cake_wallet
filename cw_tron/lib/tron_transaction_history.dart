import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_tron/tron_transaction_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';

part 'tron_transaction_history.g.dart';

class TronTransactionHistory = TronTransactionHistoryBase with _$TronTransactionHistory;

abstract class TronTransactionHistoryBase extends TransactionHistoryBase<TronTransactionInfo>
    with Store {
  TronTransactionHistoryBase(
      {required this.walletInfo, required String password, required this.encryptionFileUtils})
      : _password = password {
    transactions = ObservableMap<String, TronTransactionInfo>();
  }

  String _password;

  final WalletInfo walletInfo;
  final EncryptionFileUtils encryptionFileUtils;

  Future<void> init() async {
    clear();
    await _load();
  }

  @override
  Future<void> save() async {
    String transactionsHistoryFileNameForWallet = 'tron_transactions.json';
    try {
      final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
      String path = '$dirPath/$transactionsHistoryFileNameForWallet';
      final transactionMaps = transactions.map((key, value) => MapEntry(key, value.toJson()));
      final data = json.encode({'transactions': transactionMaps});
      await encryptionFileUtils.write(path: path, password: _password, data: data);
    } catch (e, s) {
      log('Error while saving ${walletInfo.type.name} transaction history: ${e.toString()}');
      log(s.toString());
    }
  }

  @override
  void addOne(TronTransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, TronTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

  Future<Map<String, dynamic>> _read() async {
    String transactionsHistoryFileNameForWallet = 'tron_transactions.json';
    final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
    String path = '$dirPath/$transactionsHistoryFileNameForWallet';
    final content = await encryptionFileUtils.read(path: path, password: _password);
    if (content.isEmpty) {
      return {};
    }
    return json.decode(content) as Map<String, dynamic>;
  }

  Future<void> _load() async {
    try {
      final content = await _read();
      final txs = content['transactions'] as Map<String, dynamic>? ?? {};

      for (var entry in txs.entries) {
        final val = entry.value;

        if (val is Map<String, dynamic>) {
          final tx = TronTransactionInfo.fromJson(val);
          _update(tx);
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void _update(TronTransactionInfo transaction) => transactions[transaction.id] = transaction;
}
