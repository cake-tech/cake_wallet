import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

class BaseClient extends EVMChainClient {
  BaseClient() : super(chainId: 8453);

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
  }) {
    EtherAmount? finalGasPrice = gasPrice;

    if (gasPrice == null && maxFeePerGas != null) {
      // If we have EIP-1559 parameters but no legacy gasPrice, then use maxFeePerGas as gasPrice
      finalGasPrice = maxFeePerGas;
    }

    return Transaction(
      from: from,
      to: to,
      value: amount,
      data: data,
      maxGas: maxGas,
      gasPrice: finalGasPrice,
      // maxFeePerGas: maxFeePerGas,
      // maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  @override
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

  @override
  int get chainId => 8453;
}

