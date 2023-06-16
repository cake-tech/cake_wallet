import 'dart:ffi';
import 'package:cw_monero/api/convert_utf8_to_string.dart';
import 'package:cw_monero/api/monero_output.dart';
import 'package:cw_monero/api/structs/ut8_box.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_monero/api/signatures.dart';
import 'package:cw_monero/api/types.dart';
import 'package:cw_monero/api/monero_api.dart';
import 'package:cw_monero/api/structs/coins_info_row.dart';

final refreshCoinsNative = moneroApi
    .lookup<NativeFunction<refresh_coins>>('refresh_coins')
    .asFunction<RefreshCoins>();

final coinsCountNative = moneroApi
    .lookup<NativeFunction<coins_count>>('coins_count')
    .asFunction<CoinsCount>();

final coinsGetAllNative = moneroApi.lookup<NativeFunction<get_coin>>('get_coin').asFunction<GetCoin>();


void refreshCoins(int accountIndex) => refreshCoinsNative(accountIndex);

int countOfCoins() => coinsCountNative();