import "dart:convert";

import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_tron/.secrets.g.dart" as secrets;
import "package:cw_tron/tron_transaction_model.dart";
import "package:cw_tron/tron_transactions_api.dart";
import "package:flutter/foundation.dart";

class TronScanApi implements TronTransactionsApi {
  late final _client = ProxyWrapper().getHttpIOClient();

  static const _pageSize = 50;
  static const _maxRows = 200;
  static const _maxPages = 5;

  @override
  Future<List<TronTransactionModel>> getTransactions(String address) async {
    final rows = await fetchConfirmedRows("/api/transaction", "data", {"address": address});

    return _parseRows(
      rows,
      (row) => row["hash"] is String && row["contractData"] is Map<String, dynamic>,
      TronTransactionModel.fromTronScanJson,
    );
  }

  @override
  Future<List<TronTRC20TransactionModel>> getTrc20Transactions(String address) async {
    final rows = await fetchConfirmedRows(
      "/api/token_trc20/transfers",
      "token_transfers",
      {"relatedAddress": address},
    );

    return _parseRows(
      rows,
      (row) =>
          row["transaction_id"] is String &&
          row["event_type"] == "Transfer" &&
          row["contractRet"] == "SUCCESS" &&
          (row["tokenInfo"] as Map<String, dynamic>?)?["tokenType"] == "trc20",
      TronTRC20TransactionModel.fromTronScanJson,
    );
  }

  List<T> _parseRows<T>(
    List<Map<String, dynamic>> rows,
    bool Function(Map<String, dynamic> row) conditionToKeepRow,
    T Function(Map<String, dynamic> row) parse,
  ) {
    final models = <T>[];

    for (final row in rows.where(conditionToKeepRow)) {
      try {
        models.add(parse(row));
      } catch (e) {
        printV("Skipping TronScan row ${row["hash"] ?? row["transaction_id"]}: $e");
      }
    }

    if (rows.isNotEmpty && models.isEmpty) {
      throw Exception("No TronScan row out of ${rows.length} survived");
    }

    return models;
  }

  @protected
  Future<List<Map<String, dynamic>>> fetchConfirmedRows(
    String path,
    String rowsKey,
    Map<String, String> query,
  ) async {
    final rows = <Map<String, dynamic>>[];
    int start = 0;

    for (int page = 0; page < _maxPages && rows.length < _maxRows; page++) {
      final response = await _client.get(
        Uri.https("apilist.tronscanapi.com", path, {
          ...query,
          "sort": "-timestamp",
          "limit": "$_pageSize",
          "start": "$start",
        }),
        headers: {
          if (secrets.tronScanApiKey.isNotEmpty) "TRON-PRO-API-KEY": secrets.tronScanApiKey,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("TronScan $path failed: ${response.statusCode} ${response.reasonPhrase}");
      }

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      final pageRows = (jsonResponse[rowsKey] as List<dynamic>?)?.cast<Map<String, dynamic>>();

      if (pageRows == null) {
        throw Exception("TronScan $path returned no $rowsKey");
      }

      rows.addAll(pageRows.where((row) => row["confirmed"] == true));
      start += pageRows.length;

      if (pageRows.length < _pageSize) {
        break;
      }
    }

    return rows;
  }
}
