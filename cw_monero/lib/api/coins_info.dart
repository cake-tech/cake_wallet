import 'dart:ffi';
import 'package:cw_monero/api/signatures.dart';
import 'package:cw_monero/api/types.dart';
import 'package:cw_monero/api/monero_api.dart';

final refreshCoinsNative = moneroApi
    .lookup<NativeFunction<refresh_coins>>('refresh_coins')
    .asFunction<RefreshCoins>();

final coinsCountNative = moneroApi
    .lookup<NativeFunction<coins_count>>('coins_count')
    .asFunction<CoinsCount>();


void refreshCoins(int accountIndex) => refreshCoinsNative(accountIndex);

int countOfCoins() => coinsCountNative();