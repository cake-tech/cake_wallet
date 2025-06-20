import 'dart:convert';
import 'dart:core';
import 'package:mobx/mobx.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_xelis/xelis_transaction_info.dart';

part 'xelis_transaction_history.g.dart';

const transactionsHistoryFileName = 'xelis_transactions.json';

class XelisTransactionHistory = XelisTransactionHistoryBase with _$XelisTransactionHistory;

abstract class XelisTransactionHistoryBase
    extends TransactionHistoryBase<XelisTransactionInfo> with Store {
  XelisTransactionHistoryBase(
      {required this.walletInfo, required String password, required this.encryptionFileUtils})
      : _password = password {
    transactions = ObservableMap<String, XelisTransactionInfo>();
  }

  final WalletInfo walletInfo;
  final EncryptionFileUtils encryptionFileUtils;
  String _password;

  Future<void> init() async {
    clear();
    await _load();
  }

  @override
  Future<void> save() async {
    try {
      final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
      final path = '$dirPath/$transactionsHistoryFileName';
      final transactionMaps = transactions.map((key, value) => MapEntry(key, value.toJson()));
      final data = json.encode({'transactions': transactionMaps});
      await encryptionFileUtils.write(path: path, password: _password, data: data);
    } catch (e, s) {
      printV('Error while saving xelis transaction history: ${e.toString()}');
      printV(s);
    }
  }

  @override
  void addOne(XelisTransactionInfo transaction) =>
      transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, XelisTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

  Future<Map<String, dynamic>> _read() async {
    final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
    final path = '$dirPath/$transactionsHistoryFileName';
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

      txs.entries.forEach((entry) {
        final val = entry.value;

        if (val is Map<String, dynamic>) {
          final tx = XelisTransactionInfo.fromJson(val, isAssetEnabled: (id) => true); // asset filtering needs to happen elsewhere before serializing
          addOne(tx);
        }
      });
    } catch (e) {
      printV(e);
    }
  }

  bool update(Map<String, XelisTransactionInfo> txs) {
    var foundOldTx = false;
    txs.forEach((_, tx) {
      if (!transactions.containsKey(tx.id)) {
        transactions[tx.id] = tx;
      } else {
        foundOldTx = true;
      }
    });
    return foundOldTx;
  }
}
