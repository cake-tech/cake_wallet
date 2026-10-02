import "dart:convert";

import "package:cake_wallet/core/everstake/exceptions.dart";
import "package:cake_wallet/core/everstake/models.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:http/http.dart";

class EverstakeService {
  static const _apiHost = "wallet-sdk-api.everstake.com";

  Future<Money> getEthereumMinStakeAmount() async {
    final response = await _get("min_stake_amount");
    return Money.parse(response["result"] as String, CryptoCurrency.eth);
  }

  Future<String> getEthereumFee() async {
    final response = await _get("fee");
    return response["result"] as String;
  }

  Future<EverstakeEthereumUserBalances> getEthereumUserBalances(String address) async =>
      EverstakeEthereumUserBalances.fromJson(await _get("balances/$address"));

  Future<EverstakeEthereumPoolBalances> getEthereumPoolBalances() async =>
      EverstakeEthereumPoolBalances.fromJson(await _get("balances"));

  Future<Money> getEthereumRestakedRewards(String address) async {
    final response = await _get("restaked_reward_of/$address");
    return Money.parse(response["result"] as String, CryptoCurrency.eth);
  }

  Future<EverstakeEthereumWithdrawRequest> getEthereumWithdrawRequest(String address) async =>
      EverstakeEthereumWithdrawRequest.fromJson(await _get("withdraw_request/$address"));

  Future<EverstakeEthereumWithdrawQueue> getEthereumWithdrawQueue() async =>
      EverstakeEthereumWithdrawQueue.fromJson(await _get("withdraw_request_queue_params"));

  Future<EverstakeEthereumTransaction> prepareEthereumStake({
    required String address,
    required Money amount,
    required String source,
  }) async {
    final response = await _post("stake", {
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
    required String source,
  }) async {
    final response = await _post("simulate_unstake", {
      "address": address,
      "amount": _ethereumAmount(amount),
      "allowedInterchangeNum": allowedInterchangeNum,
      "source": source,
    });
    return Money.parse(response["result"] as String, CryptoCurrency.eth);
  }

  Future<EverstakeEthereumTransaction> prepareEthereumUnstake({
    required String address,
    required Money amount,
    required int allowedInterchangeNum,
    required String source,
  }) async {
    final response = await _post("unstake", {
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
    final response = await _post("unstake_pending", {
      "address": address,
      "amount": _ethereumAmount(amount),
    });
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<EverstakeEthereumTransaction> prepareEthereumClaimWithdrawRequest(String address) async {
    final response = await _post("claim_withdraw_request", {"address": address});
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<EverstakeEthereumTransaction> prepareEthereumActivateStake(String address) async {
    final response = await _post("activate_stake", {"address": address});
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<EverstakeEthereumTransaction> prepareEthereumAutocompound(String address) async {
    final response = await _post("autocompound", {"address": address});
    return EverstakeEthereumTransaction.fromJson(response, value: Money.zero(CryptoCurrency.eth));
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/$path", {"network": "mainnet"});
    final response = await ProxyWrapper().get(clearnetUri: uri);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.https(_apiHost, "/ethereum/pool/$path", {"network": "mainnet"});
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(Response response) {
    if (response.statusCode != 200) {
      throw EverstakeException("${response.statusCode}: ${response.body}");
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _ethereumAmount(Money amount) {
    if (amount.currency != CryptoCurrency.eth) {
      throw ArgumentError.value(amount.currency, "amount.currency", "Expected ETH");
    }
    return amount.toString();
  }
}
