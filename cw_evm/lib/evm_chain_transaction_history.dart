import "dart:core";

import "package:cw_core/erc20_token.dart";
import "package:cw_core/json_transaction_history.dart";
import "package:cw_evm/evm_chain_transaction_info.dart";
import "package:cw_evm/utils/evm_chain_utils.dart";

class EVMChainTransactionHistory extends JsonTransactionHistory<EVMChainTransactionInfo> {
  EVMChainTransactionHistory({
    required super.walletInfo,
    required super.password,
    required super.encryptionFileUtils,
    required this.getCurrentChainId,
  });

  /// Function to get the current chain ID (allows transaction history to use correct file)
  final int Function() getCurrentChainId;


  @override
  String get fileName => EVMChainUtils.getTransactionHistoryFileName(getCurrentChainId());

  Iterable<Erc20Token> _tokens = const [];

  @override
  Future<void> prepareForLoad() async {
    _tokens = await Erc20Token.getAllForWallet(walletInfo.name, getCurrentChainId());
  }

  @override
  EVMChainTransactionInfo transactionFromJson(Map<String, dynamic> json) =>
      EVMChainTransactionInfo.fromJson(json, getCurrentChainId(), tokens: _tokens);

  @override
  bool shouldPersist(EVMChainTransactionInfo transaction) =>
      transaction.chainId == getCurrentChainId();

  @override
  void addOne(EVMChainTransactionInfo transaction) {
    if (transaction.chainId == getCurrentChainId()) {
      put(transaction);
    }
  }

  @override
  void addMany(Map<String, EVMChainTransactionInfo> transactions) {
    final currentChainId = getCurrentChainId();

    removeWhere((_, transaction) => transaction.chainId != currentChainId);

    for (final transaction in transactions.values) {
      if (transaction.chainId == currentChainId) {
        put(transaction);
      }
    }
  }
}
