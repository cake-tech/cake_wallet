import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_evm/evm_chain_transaction_info.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/transaction_history.dart';

part 'evm_chain_transaction_history.g.dart';

class EVMChainTransactionHistory = EVMChainTransactionHistoryBase with _$EVMChainTransactionHistory;

abstract class EVMChainTransactionHistoryBase extends TransactionHistoryBase<EVMChainTransactionInfo>
    with Store {
  EVMChainTransactionHistoryBase({
    required this.walletInfo,
    required String password,
    required this.encryptionFileUtils,
    required this.getCurrentChainId,
  }) : _password = password {
    transactions = ObservableMap<String, EVMChainTransactionInfo>();
  }

  String _password;

  final WalletInfo walletInfo;
  final EncryptionFileUtils encryptionFileUtils;
  
  /// Function to get the current chain ID (allows transaction history to use correct file)
  final int Function() getCurrentChainId;

  /// Get transaction history file name based on current chain ID
  String getTransactionHistoryFileName() {
    return EVMChainUtils.getTransactionHistoryFileNameByChainId(getCurrentChainId());
  }

  EVMChainTransactionInfo getTransactionInfo(Map<String, dynamic> val) {
    return EVMChainTransactionInfo.fromJson(val, walletInfo.type);
  }

  Future<void> init() async {
    clear();
    await _load();
  }

  @override
  Future<void> save() async {
    final transactionsHistoryFileNameForWallet = getTransactionHistoryFileName();
    try {
      final dirPath = await pathForWalletDir(name: walletInfo.name, type: walletInfo.type);
      String path = '$dirPath/$transactionsHistoryFileNameForWallet';
      final data = json.encode({'transactions': transactions});
      await encryptionFileUtils.write(path: path, password: _password, data: data);
    } catch (e, s) {
      log('Error while saving ${walletInfo.type.name} transaction history: ${e.toString()}');
      log(s.toString());
    }
  }

  @override
  void addOne(EVMChainTransactionInfo transaction) => transactions[transaction.id] = transaction;

  @override
  void addMany(Map<String, EVMChainTransactionInfo> transactions) =>
      this.transactions.addAll(transactions);

  Future<Map<String, dynamic>> _read() async {
    final transactionsHistoryFileNameForWallet = getTransactionHistoryFileName();
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
          final tx = getTransactionInfo(val);
          _update(tx);
        }
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void _update(EVMChainTransactionInfo transaction) => transactions[transaction.id] = transaction;
}
