import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class EverstakeEthereumUserBalances {
  EverstakeEthereumUserBalances.fromJson(Map<String, dynamic> json)
      : pendingBalance = Money.parse(json["pendingBalanceOf"] as String, CryptoCurrency.eth),
        pendingDepositedBalance =
            Money.parse(json["pendingDepositedBalanceOf"] as String, CryptoCurrency.eth),
        pendingRestakedRewards =
            Money.parse(json["pendingRestakedRewardOf"] as String, CryptoCurrency.eth),
        autocompoundBalance =
            Money.parse(json["autocompoundBalanceOf"] as String, CryptoCurrency.eth),
        depositedBalance = Money.parse(json["depositedBalanceOf"] as String, CryptoCurrency.eth);

  final Money pendingBalance;
  final Money pendingDepositedBalance;
  final Money pendingRestakedRewards;
  final Money autocompoundBalance;
  final Money depositedBalance;
}

class EverstakeEthereumPoolBalances {
  EverstakeEthereumPoolBalances.fromJson(Map<String, dynamic> json)
      : balance = Money.parse(json["balance"] as String, CryptoCurrency.eth),
        pendingBalance = Money.parse(json["pendingBalance"] as String, CryptoCurrency.eth),
        pendingDepositedBalance =
            Money.parse(json["pendingDepositedBalance"] as String, CryptoCurrency.eth),
        pendingRestakedRewards =
            Money.parse(json["pendingRestakedRewards"] as String, CryptoCurrency.eth),
        readyForAutocompoundRewards =
            Money.parse(json["readyforAutocompoundRewardsAmount"] as String, CryptoCurrency.eth);

  final Money balance;
  final Money pendingBalance;
  final Money pendingDepositedBalance;
  final Money pendingRestakedRewards;
  final Money readyForAutocompoundRewards;
}

class EverstakeEthereumWithdrawRequest {
  EverstakeEthereumWithdrawRequest.fromJson(Map<String, dynamic> json)
      : requested = Money.parse(json["requested"] as String, CryptoCurrency.eth),
        readyForClaim = Money.parse(json["readyForClaim"] as String, CryptoCurrency.eth);

  final Money requested;
  final Money readyForClaim;
}

class EverstakeEthereumWithdrawQueue {
  EverstakeEthereumWithdrawQueue.fromJson(Map<String, dynamic> json)
      : withdrawRequested = Money.parse(json["withdrawRequested"] as String, CryptoCurrency.eth),
        interchangeAllowed = Money.parse(json["interchangeAllowed"] as String, CryptoCurrency.eth),
        filled = Money.parse(json["filled"] as String, CryptoCurrency.eth),
        claimed = Money.parse(json["claimed"] as String, CryptoCurrency.eth);

  final Money withdrawRequested;
  final Money interchangeAllowed;
  final Money filled;
  final Money claimed;
}

class EverstakeEthereumTransaction {
  EverstakeEthereumTransaction.fromJson(Map<String, dynamic> json, {required this.value})
      : from = json["from"] as String,
        to = json["to"] as String,
        data = json["data"] as String,
        gasLimit = json["gasLimit"] as int;

  final String from;
  final String to;
  final Money value;
  final String data;
  final int gasLimit;
}
