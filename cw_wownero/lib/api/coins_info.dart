import 'package:cw_wownero/api/account_list.dart';
import 'package:monero/wownero.dart' as wownero;

wownero.Coins? coins = null;

void refreshCoins(int accountIndex) {
  coins = wownero.Wallet_coins(wptr!);
  wownero.Coins_refresh(coins!);
}

int countOfCoins() => wownero.Coins_count(coins!);

wownero.CoinsInfo getCoin(int index) => wownero.Coins_coin(coins!, index);

void freezeCoin(int index) => wownero.Coins_setFrozen(coins!, index: index);

void thawCoin(int index) => wownero.Coins_thaw(coins!, index: index);
