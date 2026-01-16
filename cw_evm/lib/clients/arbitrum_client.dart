import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

class ArbitrumClient extends EVMChainClient {
  ArbitrumClient() : super(chainId: 42161);

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
      nonce: nonce,
      // maxFeePerGas: maxFeePerGas,
      // maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  @override
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) => signedTransaction;

  @override
  int get chainId => 42161;
}

