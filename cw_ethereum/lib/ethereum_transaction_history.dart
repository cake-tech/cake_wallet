import 'dart:core';
import 'package:cw_evm/evm_chain_transaction_history.dart';

class EthereumTransactionHistory extends EVMChainTransactionHistory {
  EthereumTransactionHistory({
    required super.walletInfo,
    required super.password,
  });
}
