import 'dart:convert';
import 'dart:developer';

import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';

class RobinhoodClient extends EVMChainClient {
  RobinhoodClient() : super(chainId: 4663);

  static const _explorerHost = 'robinhoodchain.blockscout.com';

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
  Uint8List prepareSignedTransactionForSending(Uint8List signedTransaction) =>
      signedTransaction;

  @override
  int get chainId => 4663;

  @override
  Future<List<EVMChainTransactionModel>> fetchTransactions(String address,
      {String? contractAddress}) async {
    try {
      final response = await client.get(Uri.https(_explorerHost, '/api', {
        'module': 'account',
        'action': contractAddress != null ? 'tokentx' : 'txlist',
        if (contractAddress != null) 'contractaddress': contractAddress,
        'address': address,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (jsonResponse['result'] is String) {
        log(jsonResponse['result']);
        return [];
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          jsonResponse['result'] is List) {
        return parseTransactions(jsonResponse['result'] as List, address,
            contractAddress: contractAddress);
      }

      return [];
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  @override
  Future<List<EVMChainTransactionModel>> fetchInternalTransactions(
      String address) async {
    try {
      final response = await client.get(Uri.https(_explorerHost, '/api', {
        'module': 'account',
        'action': 'txlistinternal',
        'address': address,
      }));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          jsonResponse['result'] is List) {
        final symbol = EVMChainUtils.getFeeCurrency(chainId);

        return (jsonResponse['result'] as List)
            .map((e) => EVMChainTransactionModel.fromJson(
                e as Map<String, dynamic>, symbol, chainId))
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}
