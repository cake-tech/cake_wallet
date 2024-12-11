import 'package:cw_salvium/api/account_list.dart';
import 'package:monero/monero.dart' as salvium;

salvium.Coins? coins = null;

void refreshCoins(int accountIndex) {
  coins = salvium.Wallet_coins(wptr!);
  salvium.Coins_refresh(coins!);
}

int countOfCoins() => salvium.Coins_count(coins!);

salvium.CoinsInfo getCoin(int index) => salvium.Coins_coin(coins!, index);

void freezeCoin(int index) => salvium.Coins_setFrozen(coins!, index: index);

void thawCoin(int index) => salvium.Coins_thaw(coins!, index: index);
