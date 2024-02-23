import 'dart:convert';
import 'dart:core';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_solana/file.dart';
import 'package:cw_solana/solana_transaction_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';

part 'solana_transaction_history.g.dart';

const transactionsHistoryFileName = 'solana_transactions.json';

class SolanaTransactionHistory = SolanaTransactionHistoryBase with _$SolanaTransactionHistory;

abstract class SolanaTransactionHistoryBase extends TransactionHistoryBase<SolanaTransactionInfo>
    with Store {
  SolanaTransactionHistoryBase({required this.walletInfo, required String password})
      : _password = password {
    transactions = ObservableMap<String, SolanaTransactionInfo>();
  }

  final WalletInfo walletInfo;
  String _password;

  Future<void> init() async => await _load();

  @override
  Future<void> save() async {
    try {
      final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
      final path = '$dirPath/$transactionsHistoryFileName';
      final transactionMaps = transactions.map((key, value) => MapEntry(key, value.toJson()));
      final data = json.encode({'transactions': transactionMaps});
      await writeData(path: path, password: _password, data: data);
    } catch (e, s) {
      print('Error while saving solana transaction history: ${e.toString()}');
      print(s);
    }
  }

  @override
  void addOne(SolanaTransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, SolanaTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

  Future<Map<String, dynamic>> _read() async {
    final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
    final path = '$dirPath/$transactionsHistoryFileName';
    final content = await read(path: path, password: _password);
    if (content.isEmpty) {
      return {};
    }
    return json.decode(content) as Map<String, dynamic>;
  }

  Future<void> _load() async {
    try {
      final content = await _read();
      final txs = content['transactions'] as Map<String, dynamic>? ?? {};

      txs.entries.forEach((entry) {
        final val = entry.value;

        if (val is Map<String, dynamic>) {
          final tx = SolanaTransactionInfo.fromJson(val);
          _update(tx);
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _update(SolanaTransactionInfo transaction) => transactions[transaction.id] = transaction;
}
