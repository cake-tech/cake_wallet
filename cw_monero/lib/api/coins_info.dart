import 'dart:ffi';
import 'dart:isolate';

import 'package:cw_monero/api/account_list.dart';
import 'package:monero/monero.dart' as monero;
import 'package:monero/src/wallet2.dart';
import 'package:mutex/mutex.dart';

Wallet2Coins? coins = null;
final coinsMutex = Mutex();

Future<void> refreshCoins(int accountIndex) => coinsMutex.protect(() async {
      final refreshed = currentWallet!.coins();
      final coinsPtr = refreshed.ffiAddress();
      await Isolate.run(() => monero.Coins_refresh(Pointer.fromAddress(coinsPtr)));
      coins = refreshed;
    });

Future<List<Wallet2CoinsInfo>> readAllCoins() => coinsMutex.protect(() async {
      final all = coins!;
      return List.generate(all.count(), all.coin);
    });

Future<void> freezeCoin(int index) => coinsMutex.protect(() async {
      final coinsPtr = coins!.ffiAddress();
      await Isolate.run(() => monero.Coins_setFrozen(Pointer.fromAddress(coinsPtr), index: index));
    });

Future<void> thawCoin(int index) => coinsMutex.protect(() async {
      final coinsPtr = coins!.ffiAddress();
      await Isolate.run(() => monero.Coins_thaw(Pointer.fromAddress(coinsPtr), index: index));
    });
