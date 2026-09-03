import "dart:convert";

import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_tron/.secrets.g.dart" as secrets;
import "package:cw_tron/tron_transaction_model.dart";
import "package:cw_tron/tron_transactions_api.dart";
import "package:flutter/foundation.dart";

class TronGridApi implements TronTransactionsApi {
  late final _client = ProxyWrapper().getHttpIOClient();

  @override
  Future<List<TronTransactionModel>> getTransactions(String address) async {
    final jsonResponse = await fetchPage("/v1/accounts/$address/transactions");

    return (jsonResponse["data"] as List<dynamic>)
        .map((e) => TronTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TronTRC20TransactionModel>> getTrc20Transactions(String address) async {
    final jsonResponse = await fetchPage("/v1/accounts/$address/transactions/trc20");

    return (jsonResponse["data"] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((e) => e["type"] == "Transfer")
        .map(TronTRC20TransactionModel.fromJson)
        .toList();
  }

  @protected
  Future<Map<String, dynamic>> fetchPage(String path) async {
    final response = await _client.get(
      Uri.https(
        "api.trongrid.io",
        path,
        {
          "only_confirmed": "true",
          "limit": "200",
        },
      ),
      headers: {
        "Content-Type": "application/json",
        "TRON-PRO-API-KEY": secrets.tronGridApiKey,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("TronGrid $path failed: ${response.statusCode} ${response.reasonPhrase}");
    }

    final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

    if (jsonResponse["status"] == false) {
      throw Exception("TronGrid $path returned status false");
    }

    return jsonResponse;
  }
}
