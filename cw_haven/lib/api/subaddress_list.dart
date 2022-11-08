import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_haven/api/signatures.dart';
import 'package:cw_haven/api/types.dart';
import 'package:cw_haven/api/haven_api.dart';
import 'package:cw_haven/api/structs/subaddress_row.dart';
import 'package:cw_haven/api/wallet.dart';

final subaddressSizeNative = havenApi
    .lookup<NativeFunction<subaddrress_size>>('subaddrress_size')
    .asFunction<SubaddressSize>();

final subaddressRefreshNative = havenApi
    .lookup<NativeFunction<subaddrress_refresh>>('subaddress_refresh')
    .asFunction<SubaddressRefresh>();

final subaddrressGetAllNative = havenApi
    .lookup<NativeFunction<subaddress_get_all>>('subaddrress_get_all')
    .asFunction<SubaddressGetAll>();

final subaddrressAddNewNative = havenApi
    .lookup<NativeFunction<subaddress_add_new>>('subaddress_add_row')
    .asFunction<SubaddressAddNew>();

final subaddrressSetLabelNative = havenApi
    .lookup<NativeFunction<subaddress_set_label>>('subaddress_set_label')
    .asFunction<SubaddressSetLabel>();

bool isUpdating = false;

void refreshSubaddresses({required int accountIndex}) {
  try {
    isUpdating = true;
    subaddressRefreshNative(accountIndex);
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<SubaddressRow> getAllSubaddresses() {
  final size = subaddressSizeNative();
  final subaddressAddressesPointer = subaddrressGetAllNative();
  final subaddressAddresses = subaddressAddressesPointer.asTypedList(size);

  return subaddressAddresses
      .map((addr) => Pointer<SubaddressRow>.fromAddress(addr).ref)
      .toList();
}

void addSubaddressSync({required int accountIndex, required String label}) {
  final labelPointer = label.toNativeUtf8();
  subaddrressAddNewNative(accountIndex, labelPointer);
  calloc.free(labelPointer);
}

void setLabelForSubaddressSync(
    {required int accountIndex, required int addressIndex, required String label}) {
  final labelPointer = label.toNativeUtf8();

  subaddrressSetLabelNative(accountIndex, addressIndex, labelPointer);
  calloc.free(labelPointer);
}

void _addSubaddress(Map<String, dynamic> args) {
  final label = args['label'] as String;
  final accountIndex = args['accountIndex'] as int;

  addSubaddressSync(accountIndex: accountIndex, label: label);
}

void _setLabelForSubaddress(Map<String, dynamic> args) {
  final label = args['label'] as String;
  final accountIndex = args['accountIndex'] as int;
  final addressIndex = args['addressIndex'] as int;

  setLabelForSubaddressSync(
      accountIndex: accountIndex, addressIndex: addressIndex, label: label);
}

Future addSubaddress({required int accountIndex, required String label}) async {
    await compute<Map<String, Object>, void>(
        _addSubaddress, {'accountIndex': accountIndex, 'label': label});
    await store();
}

Future setLabelForSubaddress(
        {required int accountIndex, required int addressIndex, required String label}) async {
  await compute<Map<String, Object>, void>(_setLabelForSubaddress, {
    'accountIndex': accountIndex,
    'addressIndex': addressIndex,
    'label': label
  });
  await store();
}
