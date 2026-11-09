import "dart:convert";

import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:http/http.dart" as very_insecure_http_do_not_use;

class EverstakeService {
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

  Future<T> _get<T>(Uri uri) async {
    final response = await ProxyWrapper().get(clearnetUri: uri).timeout(_requestTimeout);
    return _decodeJson(response) as T;
  }

  dynamic _decodeJson(very_insecure_http_do_not_use.Response response) {
    if (response.statusCode != 200) {
      throw EverstakeResponseException(response.body, response.statusCode);
    }
    return jsonDecode(response.body);
  }
}
