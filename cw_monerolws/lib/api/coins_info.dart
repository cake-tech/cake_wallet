import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_monerolws/api/account_list.dart';
import 'package:monerolws/monerolws.dart' as monero;
import 'package:monero/src/lws_wallet2.dart';
import 'package:mutex/mutex.dart';

Wallet2Coins? coins = null;
final coinsMutex = Mutex();

Future<void> refreshCoins(int accountIndex) async {
  if (coinsMutex.isLocked) {
    return;
  }
  coins = currentWallet!.coins();
  final coinsPtr = coins!.ffiAddress();
  await coinsMutex.acquire();
  await Isolate.run(() => monero.Coins_refresh(Pointer.fromAddress(coinsPtr)));
  coinsMutex.release();
}

Future<int> countOfCoins() async {
  await coinsMutex.acquire();
  final count = coins!.count();
  coinsMutex.release();
  return count;
}

Future<Wallet2CoinsInfo> getCoin(int index) async {
  await coinsMutex.acquire();
  final coin = coins!.coin(index);
  coinsMutex.release();
  return coin;
}

Future<int?> getCoinByKeyImage(String keyImage) async {
  final count = await countOfCoins();
  for (int i = 0; i < count; i++) {
    final coin = await getCoin(i);
    if (keyImage == coin.keyImage()) {
      return i;
    }
  }
  return null;
}

Future<void> freezeCoin(int index) async {
  await coinsMutex.acquire();
  final coinsPtr = coins!.ffiAddress();
  await Isolate.run(() => monero.Coins_setFrozen(Pointer.fromAddress(coinsPtr), index: index));
  coinsMutex.release();
}

Future<void> thawCoin(int index) async {
  await coinsMutex.acquire();
  final coinsPtr = coins!.ffiAddress();
  await Isolate.run(() => monero.Coins_thaw(Pointer.fromAddress(coinsPtr), index: index));
  coinsMutex.release();
}
