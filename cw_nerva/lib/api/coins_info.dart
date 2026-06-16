import 'package:cw_nerva/api/account_list.dart';
import 'package:monero/nerva.dart' as nerva;

nerva.Coins? coins = null;

void refreshCoins(int accountIndex) {
  coins = nerva.Wallet_coins(wptr!);
  nerva.Coins_refresh(coins!);
}

int countOfCoins() => nerva.Coins_count(coins!);

nerva.CoinsInfo getCoin(int index) => nerva.Coins_coin(coins!, index);

void freezeCoin(int index) => nerva.Coins_setFrozen(coins!, index: index);

void thawCoin(int index) => nerva.Coins_thaw(coins!, index: index);
