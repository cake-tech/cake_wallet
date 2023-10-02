import 'dart:ffi';
import 'package:cw_zano/api/signatures.dart';
import 'package:cw_zano/api/types.dart';
import 'package:cw_zano/api/zano_api.dart';
import 'package:cw_zano/api/structs/zano_balance_row.dart';
import 'package:cw_zano/api/structs/zano_rate.dart';
import 'asset_types.dart';

List<ZanoBalanceRow> getZanoFullBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getZanoFullBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<ZanoBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<ZanoBalanceRow> getZanoUnlockedBalance({int accountIndex = 0}) {
  final size = assetTypesSizeNative();
  final balanceAddressesPointer = getZanoUnlockedBalanceNative(accountIndex);
  final balanceAddresses = balanceAddressesPointer.asTypedList(size);

  return balanceAddresses
      .map((addr) => Pointer<ZanoBalanceRow>.fromAddress(addr).ref)
      .toList();
}

List<ZanoRate> getRate() {
  updateRateNative();
  final size = sizeOfRateNative();
  final ratePointer = getRateNative();
  final rate = ratePointer.asTypedList(size);

  return rate.map((addr) => Pointer<ZanoRate>.fromAddress(addr).ref).toList();
}

final getZanoFullBalanceNative = zanoApi
    .lookup<NativeFunction<get_full_balance>>('get_full_balance')
    .asFunction<GetZanoFullBalance>();

final getZanoUnlockedBalanceNative = zanoApi
    .lookup<NativeFunction<get_unlocked_balance>>('get_unlocked_balance')
    .asFunction<GetZanoUnlockedBalance>();

final getRateNative =
    zanoApi.lookup<NativeFunction<get_rate>>('get_rate').asFunction<GetRate>();

final sizeOfRateNative = zanoApi
    .lookup<NativeFunction<size_of_rate>>('size_of_rate')
    .asFunction<SizeOfRate>();

final updateRateNative = zanoApi
    .lookup<NativeFunction<update_rate>>('update_rate')
    .asFunction<UpdateRate>();
