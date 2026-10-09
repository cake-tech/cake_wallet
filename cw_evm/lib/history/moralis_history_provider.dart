import "dart:convert";

import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_evm/evm_chain_transaction_model.dart";
import "package:cw_evm/history/evm_history_provider.dart";
import "package:cw_evm/utils/evm_chain_utils.dart";

class MoralisHistoryProvider implements EvmHistoryProvider {
  MoralisHistoryProvider({required this.apiKey});

  final String apiKey;

  late final client = ProxyWrapper().getHttpIOClient();

  // From https://docs.moralis.com/supported-chains (pulled 2026-09-25)
  static const Set<int> supportedChainIds = {
    1,
    137,
    56,
    42161,
    8453,
    10,
    59144,
    43114,
    25,
    100,
    88888,
    747,
    2020,
    369,
    143,
  };

  @override
  String get name => "Moralis";

  @override
  bool covers(int chainId) => apiKey.isNotEmpty && supportedChainIds.contains(chainId);

  Future<List<Map<String, dynamic>>> _fetchResultRows(
    String path,
    Map<String, String> params,
  ) async {
    final response = await client.get(
      Uri.https("deep-index.moralis.io", "/api/v2.2$path", params),
      headers: {"Accept": "application/json", "X-API-Key": apiKey},
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      printV("$name returned status ${response.statusCode} for $path");
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return [];
    }

    final result = decoded["result"];
    if (result is! List) {
      return [];
    }

    return result.whereType<Map<String, dynamic>>().toList();
  }

  List<EVMChainTransactionModel> _parseRows(
    Iterable<Map<String, dynamic>> rows,
    String hashKey,
    EVMChainTransactionModel Function(Map<String, dynamic> row) parseRow,
  ) {
    final transactions = <EVMChainTransactionModel>[];
    for (final row in rows) {
      try {
        transactions.add(parseRow(row));
      } catch (e) {
        printV("$name skipped row ${row[hashKey] ?? ""}: $e");
      }
    }

    return transactions;
  }

  @override
  Future<List<EVMChainTransactionModel>> transactions(int chainId, String address) async {
    try {
      final rows =
          await _fetchResultRows("/$address", {"chain": EVMChainUtils.hexChainId(chainId)});
      final symbol = EVMChainUtils.getFeeCurrency(chainId);

      return _parseRows(
        rows.where((row) => row["value"] != "0"),
        "hash",
        (row) => EVMChainTransactionModel(
          date: DateTime.parse(row["block_timestamp"] as String).toLocal(),
          hash: row["hash"] as String? ?? "",
          from: row["from_address"] as String? ?? "",
          to: row["to_address"] as String? ?? "",
          amount: BigInt.parse(row["value"] as String? ?? "0"),
          gasUsed: int.tryParse(row["receipt_gas_used"] as String? ?? "") ?? 0,
          gasPrice: BigInt.tryParse(row["gas_price"] as String? ?? "") ?? BigInt.zero,
          contractAddress: "",
          // Moralis does not return confirmations, but it only lists mined transactions
          confirmations: 1,
          blockNumber: int.tryParse(row["block_number"] as String? ?? "") ?? 0,
          tokenSymbol: symbol,
          tokenDecimal: null,
          isError: row["receipt_status"] == "0",
          input: row["input"] as String? ?? "",
          chainId: chainId,
        ),
      );
    } catch (e) {
      printV("$name transactions failed: $e");
      return [];
    }
  }

  @override
  Future<List<EVMChainTransactionModel>> tokenTransfers(
    int chainId,
    String address,
    String contractAddress,
  ) async {
    try {
      final chain = EVMChainUtils.hexChainId(chainId);
      final rows = await _fetchResultRows("/$address/erc20/transfers", {
        "chain": chain,
        "contract_addresses[0]": contractAddress,
      });

      final hasOutgoing = rows.any(
        (row) => (row["from_address"] as String?)?.toLowerCase() == address.toLowerCase(),
      );
      final transactionsByHash = hasOutgoing
          ? {
              for (final row in await _fetchResultRows("/$address", {"chain": chain}))
                row["hash"]: row
            }
          : const <Object?, Map<String, dynamic>>{};

      return _parseRows(
        rows.where((row) => row["value"] != "0"),
        "transaction_hash",
        (row) {
          final transaction = transactionsByHash[row["transaction_hash"]];

          return EVMChainTransactionModel(
            date: DateTime.parse(row["block_timestamp"] as String).toLocal(),
            hash: row["transaction_hash"] as String? ?? "",
            from: row["from_address"] as String? ?? "",
            to: row["to_address"] as String? ?? "",
            amount: BigInt.parse(row["value"] as String? ?? "0"),
            gasUsed: int.tryParse(transaction?["receipt_gas_used"] as String? ?? "") ?? 0,
            gasPrice: BigInt.tryParse(transaction?["gas_price"] as String? ?? "") ?? BigInt.zero,
            contractAddress: row["address"] as String? ?? contractAddress,
            confirmations: 1,
            blockNumber: int.tryParse(row["block_number"] as String? ?? "") ?? 0,
            tokenSymbol: row["token_symbol"] as String?,
            tokenDecimal: int.tryParse(row["token_decimals"] as String? ?? ""),
            isError: false,
            input: "",
            chainId: chainId,
          );
        },
      );
    } catch (e) {
      printV("$name token transfers failed: $e");
      return [];
    }
  }

  @override
  Future<List<EVMChainTransactionModel>> internalTransactions(int chainId, String address) async {
    try {
      final rows = await _fetchResultRows("/$address", {
        "chain": EVMChainUtils.hexChainId(chainId),
        "include": "internal_transactions",
      });
      final symbol = EVMChainUtils.getFeeCurrency(chainId);
      final lowerAddress = address.toLowerCase();
      final result = <EVMChainTransactionModel>[];

      for (final row in rows) {
        final internals = row["internal_transactions"];
        if (internals is! List) {
          continue;
        }

        for (final internal in internals.whereType<Map<String, dynamic>>()) {
          try {
            final from = internal["from"] as String? ?? "";
            final to = internal["to"] as String? ?? "";
            final isToOrFromWallet =
                from.toLowerCase() == lowerAddress || to.toLowerCase() == lowerAddress;
            if (!isToOrFromWallet || internal["value"] == "0") {
              continue;
            }

            result.add(
              EVMChainTransactionModel(
                date: DateTime.parse(row["block_timestamp"] as String).toLocal(),
                hash: internal["transaction_hash"] as String? ?? "",
                from: from,
                to: to,
                amount: BigInt.parse(internal["value"] as String? ?? "0"),
                gasUsed: int.tryParse(internal["gas_used"] as String? ?? "") ?? 0,
                gasPrice: BigInt.zero,
                contractAddress: "",
                confirmations: 1,
                blockNumber: int.tryParse(internal["block_number"] as String? ?? "") ?? 0,
                tokenSymbol: symbol,
                tokenDecimal: null,
                isError: internal["error"] != null,
                input: internal["input"] as String? ?? "",
                chainId: chainId,
              ),
            );
          } catch (e) {
            printV("$name skipped internal row ${internal["transaction_hash"] ?? ""}: $e");
          }
        }
      }

      return result;
    } catch (e) {
      printV("$name internal transactions failed: $e");
      return [];
    }
  }
}
