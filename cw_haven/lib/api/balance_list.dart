import 'dart:ffi';
import 'package:cw_haven/api/signatures.dart';
import 'package:cw_haven/api/types.dart';
import 'package:cw_haven/api/haven_api.dart';
import 'package:cw_haven/api/structs/haven_balance_row.dart';
import 'package:cw_haven/api/structs/haven_rate.dart';
import 'asset_types.dart';

List<HavenBalanceRow> getHavenFullBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getHavenFullBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<HavenBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<HavenBalanceRow> getHavenUnlockedBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getHavenUnlockedBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<HavenBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<HavenRate> getRate() {
  updateRateNative();
  final size = sizeOfRateNative();
  final ratePointer = getRateNative();
  final rate = ratePointer.asTypedList(size);

  return rate
      .map((addr) => Pointer<HavenRate>.fromAddress(addr).ref)
      .toList();
}

final getHavenFullBalanceNative = havenApi
    .lookup<NativeFunction<get_full_balance>>('get_full_balance')
    .asFunction<GetHavenFullBalance>();

final getHavenUnlockedBalanceNative = havenApi
    .lookup<NativeFunction<get_unlocked_balance>>('get_unlocked_balance')
    .asFunction<GetHavenUnlockedBalance>();

final getRateNative = havenApi
    .lookup<NativeFunction<get_rate>>('get_rate')
    .asFunction<GetRate>();

final sizeOfRateNative = havenApi
    .lookup<NativeFunction<size_of_rate>>('size_of_rate')
    .asFunction<SizeOfRate>();

final updateRateNative = havenApi
    .lookup<NativeFunction<update_rate>>('update_rate')
    .asFunction<UpdateRate>();