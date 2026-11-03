import "dart:convert";

import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:http/http.dart" as very_insecure_http_do_not_use;

class EverstakeService {
  // TODO(lapatric): add Cake Wallet's Everstake source once it is available
  static const source = "0";

  static const _apiHost = "wallet-sdk-api.everstake.com";
  static const _b2cApiHost = "eth-api-b2c.everstake.com";
  static const _requestTimeout = Duration(seconds: 20);

  Future<Money> getEthereumMinStakeAmount() async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/min_stake_amount", {"network": "mainnet"});
    final response = await _get<Map<String, dynamic>>(uri);
    return Money.parse(response["result"] as String, CryptoCurrency.eth);
  }

  Future<double> getEthereumFee() async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/fee", {"network": "mainnet"});
    final response = await _get<Map<String, dynamic>>(uri);
    return double.parse(response["result"] as String);
  }

  Future<double> getEthereumApr() async {
    final uri = Uri.https(_apiHost, "/assets/ethereum");
    final response = await _get<Map<String, dynamic>>(uri);
    final blockchain = response["blockchain"] as Map<String, dynamic>;
    return (blockchain["apr"] as num) / 100;
  }

  Future<EverstakeEthereumValidatorQueue> getEthereumValidatorQueue() async {
    final uri = Uri.https(_b2cApiHost, "/api/v1/validators/queue");
    final response = await _get<Map<String, dynamic>>(uri);
    return EverstakeEthereumValidatorQueue.fromJson(response);
  }

  Future<Money> getEthereumTotalRewards(String address) async {
    final uri = Uri.https(_b2cApiHost, "/api/v1/staker/$address/rewards/total");
    final response = await _get<String>(uri);
    // swagger incorrectly documents ETH amount
    return Money.parse(response, CryptoCurrency.eth, isBaseUnit: true);
  }

  Future<EverstakeEthereumUserBalances> getEthereumUserBalances(String address) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/balances/$address", {"network": "mainnet"});
    final response = await _get<Map<String, dynamic>>(uri);
    return EverstakeEthereumUserBalances.fromJson(response);
  }

  Future<Money> getEthereumRestakedRewards(String address) async {
    final uri =
        Uri.https(_apiHost, "/ethereum/pool/restaked_reward_of/$address", {"network": "mainnet"});
    final response = await _get<Map<String, dynamic>>(uri);
    return Money.parse(response["result"] as String, CryptoCurrency.eth);
  }

  Future<EverstakeEthereumWithdrawRequest> getEthereumWithdrawRequest(String address) async {
    final uri =
        Uri.https(_apiHost, "/ethereum/pool/withdraw_request/$address", {"network": "mainnet"});
    final response = await _get<Map<String, dynamic>>(uri);
    return EverstakeEthereumWithdrawRequest.fromJson(response);
  }

  Future<EverstakeEthereumTransaction> prepareEthereumStake({
    required String address,
    required Money amount,
  }) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/stake", {"network": "mainnet"});
    final response = await _post(uri, {
      "address": address,
      "amount": _ethereumAmount(amount),
      "source": source,
    });
    return EverstakeEthereumTransaction.fromJson(response, value: amount);
  }

  Future<Money> simulateEthereumUnstake({
    required String address,
    required Money amount,
    required int allowedInterchangeNum,
  }) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/simulate_unstake", {"network": "mainnet"});
    final response = await _post(uri, {
      "address": address,
      "amount": _ethereumAmount(amount),
      "allowedInterchangeNum": allowedInterchangeNum,
      "source": source,
    });
    return Money.parse((response["result"] as num).toStringAsFixed(18), CryptoCurrency.eth);
  }

  Future<EverstakeEthereumTransaction> prepareEthereumUnstake({
    required String address,
    required Money amount,
    required int allowedInterchangeNum,
  }) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/unstake", {"network": "mainnet"});
    final response = await _post(uri, {
      "address": address,
      "amount": _ethereumAmount(amount),
      "allowedInterchangeNum": allowedInterchangeNum,
      "source": source,
    });
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<EverstakeEthereumTransaction> prepareEthereumUnstakePending({
    required String address,
    required Money amount,
  }) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/unstake_pending", {"network": "mainnet"});
    final response = await _post(uri, {
      "address": address,
      "amount": _ethereumAmount(amount),
    });
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<EverstakeEthereumTransaction> prepareEthereumClaimWithdrawRequest(String address) async {
    final uri =
        Uri.https(_apiHost, "/ethereum/pool/claim_withdraw_request", {"network": "mainnet"});
    final response = await _post(uri, {"address": address});
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<T> _get<T>(Uri uri) async {
    final response = await ProxyWrapper().get(clearnetUri: uri).timeout(_requestTimeout);
    return _decodeJson(response) as T;
  }

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, dynamic> body) async {
    final response = await ProxyWrapper()
        .post(
          clearnetUri: uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);
    return _decodeJson(response) as Map<String, dynamic>;
  }

  dynamic _decodeJson(very_insecure_http_do_not_use.Response response) {
    if (response.statusCode != 200) {
      throw EverstakeResponseException(response.body, response.statusCode);
    }
    return jsonDecode(response.body);
  }

  String _ethereumAmount(Money amount) {
    if (amount.currency != CryptoCurrency.eth) {
      throw ArgumentError.value(amount.currency, "amount.currency", "Expected ETH");
    }
    return amount.toString();
  }
}
