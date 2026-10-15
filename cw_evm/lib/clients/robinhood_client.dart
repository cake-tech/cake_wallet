import "package:cw_evm/clients/evm_chain_client.dart";
import "package:flutter/foundation.dart";
import "package:web3dart/web3dart.dart";

class RobinhoodClient extends EVMChainClient {
  RobinhoodClient() : super(chainId: 4663);

  @override
  Transaction createTransaction({
    required EthereumAddress from,
    required EthereumAddress to,
    required EtherAmount amount,
    EtherAmount? maxPriorityFeePerGas,
    Uint8List? data,
    int? maxGas,
    EtherAmount? gasPrice,
    EtherAmount? maxFeePerGas,
    int? nonce,
  }) {
    EtherAmount? finalGasPrice = gasPrice;

    if (gasPrice == null && maxFeePerGas != null) {
      finalGasPrice = maxFeePerGas;
    }

    return Transaction(
      from: from,
      to: to,
      value: amount,
      data: data,
      maxGas: maxGas,
      gasPrice: finalGasPrice,
      nonce: nonce,
    );
  }

  @override
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

  @override
  int get chainId => 4663;
}
