import 'dart:ffi';
import 'package:cw_salvium/api/signatures.dart';
import 'package:cw_salvium/api/types.dart';
import 'package:cw_salvium/api/salvium_api.dart';
import 'package:cw_salvium/api/structs/salvium_balance_row.dart';
import 'package:cw_salvium/api/structs/salvium_rate.dart';
import 'asset_types.dart';

List<SalviumBalanceRow> getSalviumFullBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getSalviumFullBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<SalviumBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<SalviumBalanceRow> getSalviumUnlockedBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getSalviumUnlockedBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<SalviumBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<SalviumRate> getRate() {
  updateRateNative();
  final size = sizeOfRateNative();
  final ratePointer = getRateNative();
  final rate = ratePointer.asTypedList(size);

  return rate
      .map((addr) => Pointer<SalviumRate>.fromAddress(addr).ref)
      .toList();
}

final getSalviumFullBalanceNative = salviumApi
    .lookup<NativeFunction<get_full_balance>>('get_full_balance')
    .asFunction<GetSalviumFullBalance>();

final getSalviumUnlockedBalanceNative = salviumApi
    .lookup<NativeFunction<get_unlocked_balance>>('get_unlocked_balance')
    .asFunction<GetSalviumUnlockedBalance>();

final getRateNative = salviumApi
    .lookup<NativeFunction<get_rate>>('get_rate')
    .asFunction<GetRate>();

final sizeOfRateNative = salviumApi
    .lookup<NativeFunction<size_of_rate>>('size_of_rate')
    .asFunction<SizeOfRate>();

final updateRateNative = salviumApi
    .lookup<NativeFunction<update_rate>>('update_rate')
    .asFunction<UpdateRate>();
