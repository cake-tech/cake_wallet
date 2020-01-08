import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_monero/signatures.dart';
import 'package:cw_monero/types.dart';
import 'package:cw_monero/monero_api.dart';
import 'package:cw_monero/structs/subaddress_row.dart';

final subaddressSizeNative = moneroApi
    .lookup<NativeFunction<subaddrress_size>>('subaddrress_size')
    .asFunction<SubaddressSize>();

final subaddressRefreshNative = moneroApi
    .lookup<NativeFunction<subaddrress_refresh>>('subaddress_refresh')
    .asFunction<SubaddressRefresh>();

final subaddrressGetAllNative = moneroApi
    .lookup<NativeFunction<subaddress_get_all>>('subaddrress_get_all')
    .asFunction<SubaddressGetAll>();

final subaddrressAddNewNative = moneroApi
    .lookup<NativeFunction<subaddress_add_new>>('subaddress_add_row')
    .asFunction<SubaddressAddNew>();

final subaddrressSetLabelNative = moneroApi
    .lookup<NativeFunction<subaddress_set_label>>('subaddress_set_label')
    .asFunction<SubaddressSetLabel>();

void refreshSubaddresses({int accountIndex}) =>
    subaddressRefreshNative(accountIndex);

List<SubaddressRow> getAllSubaddresses() {
  refreshSubaddresses(accountIndex: 0);
  final size = subaddressSizeNative();
  final subaddressAddressesPointer = subaddrressGetAllNative();
  final subaddressAddresses = subaddressAddressesPointer.asTypedList(size);

  return subaddressAddresses
      .map((addr) => Pointer<SubaddressRow>.fromAddress(addr).ref)
      .toList();
}

void addSubaddressSync({int accountIndex, String label}) {
  final labelPointer = Utf8.toUtf8(label);
  subaddrressAddNewNative(accountIndex, labelPointer);
  free(labelPointer);
}

void setLabelForSubaddressSync(
    {int accountIndex, int addressIndex, String label}) {
  final labelPointer = Utf8.toUtf8(label);
  
  subaddrressSetLabelNative(accountIndex, addressIndex, labelPointer);
  free(labelPointer);
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

Future addSubaddress({int accountIndex, String label}) async =>
    compute(_addSubaddress, {'accountIndex': accountIndex, 'label': label});

Future setLabelForSubaddress(
        {int accountIndex, int addressIndex, String label}) =>
    compute(_setLabelForSubaddress, {
      'accountIndex': accountIndex,
      'addressIndex': addressIndex,
      'label': label
    });
