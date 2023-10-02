import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_zano/api/balance_list.dart';
import 'package:cw_zano/api/structs/zano_balance_row.dart';

const inactiveBalances = [
  CryptoCurrency.xcad,
  CryptoCurrency.xjpy,
  CryptoCurrency.xnok,
  CryptoCurrency.xnzd
];

Map<CryptoCurrency, MoneroBalance> getZanoBalance({required int accountIndex}) {
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
}
