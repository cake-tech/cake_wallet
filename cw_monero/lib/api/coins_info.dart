import 'package:cw_monero/api/account_list.dart';
import 'package:monero/monero.dart' as monero;

monero.Coins? coins = null;

void refreshCoins(int accountIndex) {
  coins = monero.Wallet_coins(wptr!);
  monero.Coins_refresh(coins!);
}

int countOfCoins() => monero.Coins_count(coins!);

monero.CoinsInfo getCoin(int index) => monero.Coins_coin(coins!, index);

void freezeCoin(int index) => monero.Coins_setFrozen(coins!, index: index);

void thawCoin(int index) => monero.Coins_thaw(coins!, index: index);
