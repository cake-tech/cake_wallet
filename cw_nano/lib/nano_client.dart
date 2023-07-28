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
  // bit of a hack since we need access to a node in a weird location:
  static const String BACKUP_NODE_URI = "rpc.nano.to";

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
    // this is the preferred rpc call but the test node isn't returning this one:
    // final response = await _httpClient.post(
    //   _node!.uri,
    //   headers: {"Content-Type": "application/json"},
    //   body: jsonEncode(
    //     {
    //       "action": "account_balance",
    //       "account": address,
    //     },
    //   ),
    // );
    // final data = await jsonDecode(response.body);
    // final String currentBalance = data["balance"] as String;
    // final String receivableBalance = data["receivable"] as String;
    // final BigInt cur = BigInt.parse(currentBalance);
    // final BigInt rec = BigInt.parse(receivableBalance);

    final response = await _httpClient.post(
      _node!.uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(
        {
          "action": "accounts_balances",
          "accounts": [address],
        },
      ),
    );
    final data = await jsonDecode(response.body);
    final String currentBalance = data["balances"][address]["balance"] as String;
    final String receivableBalance = data["balances"][address]["receivable"] as String;
    final BigInt cur = BigInt.parse(currentBalance);
    final BigInt rec = BigInt.parse(receivableBalance);
    return NanoBalance(currentBalance: cur, receivableBalance: rec);
  }

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
            "count": "250", // TODO: pick a number
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
}
