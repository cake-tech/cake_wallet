import 'dart:ffi';

import 'package:cw_wownero/api/signatures.dart';
import 'package:cw_wownero/api/structs/subaddress_row.dart';
import 'package:cw_wownero/api/types.dart';
import 'package:cw_wownero/api/wallet.dart';
import 'package:cw_wownero/api/wownero_api.dart';
import 'package:ffi/ffi.dart';
import 'package:ffi/ffi.dart' as pkgffi;
import 'package:flutter/foundation.dart';

final subaddressSizeNative = wowneroApi
    .lookup<NativeFunction<subaddrress_size>>('subaddrress_size')
    .asFunction<SubaddressSize>();

final subaddressRefreshNative = wowneroApi
    .lookup<NativeFunction<subaddrress_refresh>>('subaddress_refresh')
    .asFunction<SubaddressRefresh>();

final subaddrressGetAllNative = wowneroApi
    .lookup<NativeFunction<subaddress_get_all>>('subaddrress_get_all')
    .asFunction<SubaddressGetAll>();

final subaddrressAddNewNative = wowneroApi
    .lookup<NativeFunction<subaddress_add_new>>('subaddress_add_row')
    .asFunction<SubaddressAddNew>();

final subaddrressSetLabelNative = wowneroApi
    .lookup<NativeFunction<subaddress_set_label>>('subaddress_set_label')
    .asFunction<SubaddressSetLabel>();

bool isUpdating = false;

void refreshSubaddresses({required int? accountIndex}) {
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

void addSubaddressSync({int? accountIndex, required String label}) {
  final labelPointer = label.toNativeUtf8();
  subaddrressAddNewNative(accountIndex, labelPointer);
  pkgffi.calloc.free(labelPointer);
}

void setLabelForSubaddressSync(
    {int? accountIndex, int? addressIndex, required String label}) {
  final labelPointer = label.toNativeUtf8();

  subaddrressSetLabelNative(accountIndex, addressIndex, labelPointer);
  pkgffi.calloc.free(labelPointer);
}

void _addSubaddress(Map<String, dynamic> args) {
  final label = args['label'] as String;
  final accountIndex = args['accountIndex'] as int?;

  addSubaddressSync(accountIndex: accountIndex, label: label);
}

void _setLabelForSubaddress(Map<String, dynamic> args) {
  final label = args['label'] as String;
  final accountIndex = args['accountIndex'] as int?;
  final addressIndex = args['addressIndex'] as int?;

  setLabelForSubaddressSync(
      accountIndex: accountIndex, addressIndex: addressIndex, label: label);
}

Future addSubaddress({int? accountIndex, String? label}) async {
  await compute<Map<String, Object?>, void>(
      _addSubaddress, {'accountIndex': accountIndex, 'label': label});
  await store();
}

Future setLabelForSubaddress(
    {int? accountIndex, int? addressIndex, String? label}) async {
  await compute<Map<String, Object?>, void>(_setLabelForSubaddress, {
    'accountIndex': accountIndex,
    'addressIndex': addressIndex,
    'label': label
  });
  await store();
}
