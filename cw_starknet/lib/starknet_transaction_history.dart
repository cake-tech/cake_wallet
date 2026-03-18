import 'dart:convert';
import 'dart:core';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';

part 'starknet_transaction_history.g.dart';

const transactionsHistoryFileName = 'starknet_transactions.json';

class StarknetTransactionHistory = StarknetTransactionHistoryBase
    with _$StarknetTransactionHistory;

abstract class StarknetTransactionHistoryBase
    extends TransactionHistoryBase<StarknetTransactionInfo> with Store {
  StarknetTransactionHistoryBase({
    required this.walletInfo,
    required String password,
    required this.encryptionFileUtils,
  }) : _password = password {
    transactions = ObservableMap<String, StarknetTransactionInfo>();
  }

  final WalletInfo walletInfo;
  final EncryptionFileUtils encryptionFileUtils;
  final String _password;

  Future<void> init() async {
    clear();
    await _load();
  }

  @override
  Future<void> save() async {
    try {
      final dirPath =
          await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
      final path = '$dirPath/$transactionsHistoryFileName';
      final transactionMaps =
          transactions.map((key, value) => MapEntry(key, value.toJson()));
      final data = json.encode({'transactions': transactionMaps});
      await encryptionFileUtils.write(
          path: path, password: _password, data: data);
    } catch (e, s) {
      printV(
          'Error while saving starknet transaction history: ${e.toString()}');
      printV(s);
    }
  }

  @override
  void addOne(StarknetTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, StarknetTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

  Future<Map<String, dynamic>> _read() async {
    final dirPath =
        await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
    final path = '$dirPath/$transactionsHistoryFileName';
    final content =
        await encryptionFileUtils.read(path: path, password: _password);
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
          final tx = StarknetTransactionInfo.fromJson(val);
          _update(tx);
        }
      }
    } catch (e) {
      printV(e);
    }
  }

  void _update(StarknetTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;
}
