import "dart:convert";
import "dart:developer";

import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_evm/evm_chain_transaction_model.dart";
import "package:cw_evm/history/evm_history_provider.dart";
import "package:cw_evm/utils/evm_chain_utils.dart";

class EtherscanHistoryProvider implements EvmHistoryProvider {
  EtherscanHistoryProvider({required this.apiKey});

  final String apiKey;

  late final client = ProxyWrapper().getHttpIOClient();

  // From https://api.etherscan.io/v2/chainlist (63 chains, pulled 2026-09-25)
  static const Set<int> supportedChainIds = {
    1,
    11155111,
    560048,
    56,
    97,
    137,
    80002,
    8453,
    84532,
    42161,
    421614,
    59144,
    59141,
    81457,
    168587773,
    10,
    11155420,
    43114,
    43113,
    199,
    1029,
    42220,
    11142220,
    252,
    2523,
    100,
    5000,
    5003,
    4352,
    43522,
    204,
    5611,
    167000,
    167013,
    50,
    51,
    33139,
    33111,
    480,
    4801,
    146,
    14601,
    130,
    1301,
    2741,
    11124,
    80094,
    80069,
    143,
    10143,
    999,
    747474,
    737373,
    1329,
    1328,
    988,
    2201,
    9745,
    9746,
    4326,
    6343,
    4663,
    5042,
  };

  @override
  String get name => "Etherscan";

  @override
  bool covers(int chainId) => apiKey.isNotEmpty && supportedChainIds.contains(chainId);

  Uri queryUri(int chainId, Map<String, String> params) => Uri.https(
        "api.etherscan.io",
        "/v2/api",
        {"chainid": "$chainId", ...params, "apikey": apiKey},
      );

  @override
  Future<List<EVMChainTransactionModel>> transactions(int chainId, String address) =>
      _fetchTransactions(chainId, address);

  @override
  Future<List<EVMChainTransactionModel>> tokenTransfers(
    int chainId,
    String address,
    String contractAddress,
  ) =>
      _fetchTransactions(chainId, address, contractAddress: contractAddress);

  Future<List<EVMChainTransactionModel>> _fetchTransactions(
    int chainId,
    String address, {
    String? contractAddress,
  }) async {
    try {
      final response = await client
          .get(
            queryUri(chainId, {
              "module": "account",
              "action": contractAddress != null ? "tokentx" : "txlist",
              if (contractAddress != null) "contractaddress": contractAddress,
              "address": address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (jsonResponse["result"] is String) {
        log(jsonResponse["result"]);
        return [];
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final res = jsonResponse["result"] as List;
        res.removeWhere((e) => e["value"] == "0");

        // Filter out spam native transactions below 0.00001 ETH (10000000000000 wei)
        if (contractAddress == null) {
          final spamThresholdWei = BigInt.from(10000000000000);
          res.removeWhere((e) {
            try {
              final value = BigInt.parse(e["value"] ?? "0");
              final isIncoming = e["to"]?.toLowerCase() == address.toLowerCase() &&
                  e["from"]?.toLowerCase() != address.toLowerCase();
              return isIncoming && value < spamThresholdWei;
            } catch (_) {
              return false;
            }
          });
        }

        // Merge split transfers (same hash + same token)
        final Map<String, Map<String, dynamic>> mergedMap = {};
        for (final tx in res) {
          final hash = tx["hash"];
          final key = '${hash}_${tx['contractAddress'] ?? ''}';

          if (mergedMap.containsKey(key)) {
            try {
              final currentNet = getNetFlow(mergedMap[key]!, address);
              final newNet = getNetFlow(tx, address);
              final totalNet = currentNet + newNet;

              mergedMap[key]!["value"] = totalNet.abs().toString();
              if (totalNet < BigInt.zero) {
                mergedMap[key]!["from"] = address;
              } else {
                mergedMap[key]!["to"] = address;
                mergedMap[key]!["from"] = "";
              }
            } catch (e) {
              printV("Error merging transaction values: $e");
            }
          } else {
            mergedMap[key] = Map<String, dynamic>.from(tx);
          }
        }

        final mergedList = mergedMap.values.toList();

        final symbol = EVMChainUtils.getFeeCurrency(chainId);

        return mergedList
            .map((e) => EVMChainTransactionModel.fromJson(e, symbol, chainId))
            .toList();
      }

      return [];
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  BigInt getNetFlow(Map<String, dynamic> txData, String address) {
    final val = BigInt.parse(txData["value"] ?? "0");
    final isIncoming = txData["to"]?.toLowerCase() == address.toLowerCase();
    final isOutgoing = txData["from"]?.toLowerCase() == address.toLowerCase();

    if (isIncoming && !isOutgoing) {
      return val;
    }

    if (isOutgoing && !isIncoming) {
      return -val;
    }

    return BigInt.zero;
  }

  @override
  Future<List<EVMChainTransactionModel>> internalTransactions(int chainId, String address) async {
    try {
      final response = await client
          .get(
            queryUri(chainId, {
              "module": "account",
              "action": "txlistinternal",
              "address": address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          jsonResponse["result"] is List) {
        final symbol = EVMChainUtils.getFeeCurrency(chainId);

        return (jsonResponse["result"] as List)
            .map(
              (e) => EVMChainTransactionModel.fromJson(e as Map<String, dynamic>, symbol, chainId),
            )
            .toList();
      }

      printV(
        '$name API returned invalid response for internal transactions: status=${jsonResponse['status']}, statusCode=${response.statusCode}',
      );
      return [];
    } catch (e, stackTrace) {
      printV("Error fetching internal transactions: ${e.toString()}");
      printV("Stack trace: ${stackTrace.toString()}");
      return [];
    }
  }
}
