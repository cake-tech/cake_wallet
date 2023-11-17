import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_zano/api/balance_list.dart';
import 'package:cw_zano/api/structs/zano_balance_row.dart';

class ZanoBalance extends Balance {
  ZanoBalance(super.available, super.additional);
  late int unlockedBalance;
  @override
  // TODO: implement formattedAdditionalBalance
  String get formattedAdditionalBalance {
    // TODO: fix it
    return "0";
  }

  @override
  // TODO: implement formattedAvailableBalance
  String get formattedAvailableBalance {
    // TODO: fix it
    return "0";
  }

}

Map<CryptoCurrency, ZanoBalance> getZanoBalance() {
  // TODO: fix it
  return { CryptoCurrency.zano: ZanoBalance(0, 0) };
}

/*Map<CryptoCurrency, MoneroBalance> getZanoBalance({required int accountIndex}) {
  final fullBalances = getZanoFullBalance(accountIndex: accountIndex);
  final unlockedBalances = getZanoUnlockedBalance(accountIndex: accountIndex);
  final zanoBalances = <CryptoCurrency, MoneroBalance>{};
  final balancesLength = fullBalances.length;

  for (int i = 0; i < balancesLength; i++) {
    final assetType = fullBalances[i].getAssetType();
    final fullBalance = fullBalances[i].getAmount();
    final unlockedBalance = unlockedBalances[i].getAmount();
    final moneroBalance = MoneroBalance(
        fullBalance: fullBalance, unlockedBalance: unlockedBalance);
    final currency = CryptoCurrency.fromString(assetType);

    if (inactiveBalances.indexOf(currency) >= 0) {
      continue;
    }

    zanoBalances[currency] = moneroBalance;
  }

  return zanoBalances;
}*/
