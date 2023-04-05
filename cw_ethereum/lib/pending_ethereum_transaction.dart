import 'package:cw_core/pending_transaction.dart';
import 'package:web3dart/web3dart.dart';

class PendingEthereumTransaction with PendingTransaction {
  final Function sendTransaction;
  final TransactionInformation transactionInformation;

  PendingEthereumTransaction({
    required this.sendTransaction,
    required this.transactionInformation,
  });

  @override
  String get amountFormatted =>
      transactionInformation.value.getValueInUnit(EtherUnit.ether).toString();

  @override
  Future<void> commit() async => sendTransaction();

  @override
  String get feeFormatted {
    final fee = transactionInformation.gasPrice.getInWei * BigInt.from(transactionInformation.gas);

    return EtherAmount.inWei(fee).getValueInUnit(EtherUnit.ether).toString();
  }

  @override
  String get hex => transactionInformation.hash;

  @override
  String get id => transactionInformation.hashCode.toString();
}
