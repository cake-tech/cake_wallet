import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_monero/api/account_list.dart';
import 'package:monero/monero.dart' as monero;
import 'package:mutex/mutex.dart';

monero.Coins? coins = null;
final coinsMutex = Mutex();

Future<void> refreshCoins(int accountIndex) async {
  if (coinsMutex.isLocked) {
    return;
  }
  coins = monero.Wallet_coins(wptr!);
  final coinsPtr = coins!.address;
  await coinsMutex.acquire();
  await Isolate.run(() => monero.Coins_refresh(Pointer.fromAddress(coinsPtr)));
  coinsMutex.release();
}

Future<int> countOfCoins() async {
  await coinsMutex.acquire();
  final count = monero.Coins_count(coins!);
  coinsMutex.release();
  return count;
}

Future<monero.CoinsInfo> getCoin(int index) async {
  await coinsMutex.acquire();
  final coin = monero.Coins_coin(coins!, index);
  coinsMutex.release();
  return coin;
}

Future<int?> getCoinByKeyImage(String keyImage) async {
  final count = await countOfCoins();
  for (int i = 0; i < count; i++) {
    final coin = await getCoin(i);
    final coinAddress = monero.CoinsInfo_keyImage(coin);
    if (keyImage == coinAddress) {
      return i;
    }
  }
  return null;
}

Future<void> freezeCoin(int index) async {
  await coinsMutex.acquire();
  monero.Coins_setFrozen(coins!, index: index);
  coinsMutex.release();
}

Future<void> thawCoin(int index) async {
  await coinsMutex.acquire();
  monero.Coins_thaw(coins!, index: index);
  coinsMutex.release();
}
