import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_transaction_model.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/contracts/erc20.dart';
import 'package:cw_core/node.dart';

class NanoClient {
  final _httpClient = Client();
  StreamSubscription<Transfer>? subscription;
  Node? _node;

  bool connect(Node node) {
    try {
      _node = node;
      return true;
    } catch (e) {
      return false;
    }
  }

  void setListeners(EthereumAddress userAddress, Function(FilterEvent) onNewTransaction) async {}

  Future<NanoBalance> getBalance(String address) async {
    return NanoBalance(currentBalance: BigInt.zero, receivableBalance: BigInt.zero);
  }

  // Future<PendingEthereumTransaction> signTransaction({
  //   required EthPrivateKey privateKey,
  //   required String toAddress,
  //   required String amount,
  //   required int gas,
  //   required EthereumTransactionPriority priority,
  //   required CryptoCurrency currency,
  //   required int exponent,
  //   String? contractAddress,
  // }) async {
  //   assert(currency == CryptoCurrency.eth || contractAddress != null);

  //   bool _isEthereum = currency == CryptoCurrency.eth;

  //   final price = await _client!.getGasPrice();

  //   final Transaction transaction = Transaction(
  //     from: privateKey.address,
  //     to: EthereumAddress.fromHex(toAddress),
  //     maxGas: gas,
  //     gasPrice: price,
  //     value: _isEthereum ? EtherAmount.inWei(BigInt.parse(amount)) : EtherAmount.zero(),
  //   );

  //   final signedTransaction = await _client!.signTransaction(privateKey, transaction);

  //   final BigInt estimatedGas;
  //   final Function _sendTransaction;

  //   if (_isEthereum) {
  //     estimatedGas = BigInt.from(21000);
  //     _sendTransaction = () async => await sendTransaction(signedTransaction);
  //   } else {
  //     estimatedGas = BigInt.from(50000);

  //     final erc20 = Erc20(
  //       client: _client!,
  //       address: EthereumAddress.fromHex(contractAddress!),
  //     );

  //     _sendTransaction = () async {
  //       await erc20.transfer(
  //         EthereumAddress.fromHex(toAddress),
  //         BigInt.parse(amount),
  //         credentials: privateKey,
  //       );
  //     };
  //   }

  //   return PendingEthereumTransaction(
  //     signedTransaction: signedTransaction,
  //     amount: amount,
  //     fee: estimatedGas * price.getInWei,
  //     sendTransaction: _sendTransaction,
  //     exponent: exponent,
  //   );
  // }

  Future<dynamic> getTransactionDetails(String transactionHash) async {
    throw UnimplementedError();
  }

  void stop() {
    subscription?.cancel();
    _httpClient?.close();
  }

  Future<List<NanoTransactionModel>> fetchTransactions(String address) async {
    try {
      final response = await _httpClient.post(_node!.uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "action": "account_history",
            "account": address,
            "count": "250",// TODO: pick a number
            // "raw": true,
          }));
      final data = await jsonDecode(response.body);
      final transactions = data["history"] is List ? data["history"] as List<dynamic> : [];

      // Map the transactions list to NanoTransactionModel using the factory
      // reversed so that the DateTime is correct when local_timestamp is absent
      return transactions.reversed
          .map<NanoTransactionModel>(
              (transaction) => NanoTransactionModel.fromJson(transaction as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

// Future<int> _getDecimalPlacesForContract(DeployedContract contract) async {
//     final String abi = await rootBundle.loadString("assets/abi_json/erc20_abi.json");
//     final contractAbi = ContractAbi.fromJson(abi, "ERC20");
//
//     final contract = DeployedContract(
//       contractAbi,
//       EthereumAddress.fromHex(_erc20Currencies[erc20Currency]!),
//     );
//     final decimalsFunction = contract.function('decimals');
//     final decimals = await _client!.call(
//       contract: contract,
//       function: decimalsFunction,
//       params: [],
//     );
//
//     int exponent = int.parse(decimals.first.toString());
//     return exponent;
//   }
}
