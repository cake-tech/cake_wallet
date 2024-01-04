import 'package:cw_evm/pending_evm_chain_transaction.dart';

class PendingEthereumTransaction extends PendingEVMChainTransaction {
  PendingEthereumTransaction({
    required super.sendTransaction,
    required super.signedTransaction,
    required super.fee,
    required super.amount,
    required super.exponent,
  });
}
