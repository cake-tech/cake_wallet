import 'dart:ffi';
import 'package:cw_wownero/api/signatures.dart';
import 'package:cw_wownero/api/structs/coins_info_row.dart';
import 'package:cw_wownero/api/types.dart';
import 'package:cw_wownero/api/wownero_api.dart';

final refreshCoinsNative = wowneroApi
    .lookup<NativeFunction<refresh_coins>>('refresh_coins')
    .asFunction<RefreshCoins>();

final coinsCountNative = wowneroApi
    .lookup<NativeFunction<coins_count>>('coins_count')
    .asFunction<CoinsCount>();

final coinNative = wowneroApi
    .lookup<NativeFunction<coin>>('coin')
    .asFunction<GetCoin>();

final freezeCoinNative = wowneroApi
    .lookup<NativeFunction<freeze_coin>>('freeze_coin')
    .asFunction<FreezeCoin>();

final thawCoinNative = wowneroApi
    .lookup<NativeFunction<thaw_coin>>('thaw_coin')
    .asFunction<ThawCoin>();

void refreshCoins(int accountIndex) => refreshCoinsNative(accountIndex);

int countOfCoins() => coinsCountNative();

CoinsInfoRow getCoin(int index) => coinNative(index).ref;

void freezeCoin(int index) => freezeCoinNative(index);

void thawCoin(int index) => thawCoinNative(index);
