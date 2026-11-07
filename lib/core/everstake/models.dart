import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class EverstakeEthereumUserBalances {
  EverstakeEthereumUserBalances.fromJson(Map<String, dynamic> json)
      : pendingBalance = Money.parse(json["pendingBalanceOf"] as String, CryptoCurrency.eth),
        pendingDepositedBalance =
            Money.parse(json["pendingDepositedBalanceOf"] as String, CryptoCurrency.eth),
        autocompoundBalance =
            Money.parse(json["autocompoundBalanceOf"] as String, CryptoCurrency.eth);

  final Money pendingBalance;
  final Money pendingDepositedBalance;
  final Money autocompoundBalance;
}

class EverstakeEthereumWithdrawRequest {
  EverstakeEthereumWithdrawRequest.fromJson(Map<String, dynamic> json)
      : requested = Money.parse(json["requested"] as String, CryptoCurrency.eth),
        readyForClaim = Money.parse(json["readyForClaim"] as String, CryptoCurrency.eth);

  final Money requested;
  final Money readyForClaim;
}

class EverstakeEthereumValidatorQueue {
  EverstakeEthereumValidatorQueue.fromJson(Map<String, dynamic> json)
      : activationTime = Duration(
          seconds:
              (json["validator_activation_time"] as int) + (json["validator_adding_delay"] as int),
        ),
        withdrawalTime = Duration(
          seconds: (json["validator_exit_time"] as int) + (json["validator_withdraw_time"] as int),
        );

  final Duration activationTime;
  final Duration withdrawalTime;
}

class EverstakeEthereumTransaction {
  // The API rounds value through a JavaScript number; retain the exact requested ETH value.
  EverstakeEthereumTransaction.fromJson(Map<String, dynamic> json, {required this.value})
      : from = json["from"] as String,
        to = json["to"] as String,
        data = json["data"] as String;

  final String from;
  final String to;
  final Money value;
  final String data;
}
