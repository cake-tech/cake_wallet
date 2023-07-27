import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:cw_haven/api/signatures.dart';
import 'package:cw_haven/api/types.dart';
import 'package:cw_haven/api/haven_api.dart';
import 'package:cw_haven/api/structs/account_row.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_haven/api/wallet.dart';

final accountSizeNative = havenApi
    .lookup<NativeFunction<account_size>>('account_size')
    .asFunction<SubaddressSize>();

final accountRefreshNative = havenApi
    .lookup<NativeFunction<account_refresh>>('account_refresh')
    .asFunction<AccountRefresh>();

final accountGetAllNative = havenApi
    .lookup<NativeFunction<account_get_all>>('account_get_all')
    .asFunction<AccountGetAll>();

final accountAddNewNative = havenApi
    .lookup<NativeFunction<account_add_new>>('account_add_row')
    .asFunction<AccountAddNew>();

final accountSetLabelNative = havenApi
    .lookup<NativeFunction<account_set_label>>('account_set_label_row')
    .asFunction<AccountSetLabel>();

bool isUpdating = false;

void refreshAccounts() {
  try {
    isUpdating = true;
    accountRefreshNative();
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<AccountRow> getAllAccount() {
  final size = accountSizeNative();
  final accountAddressesPointer = accountGetAllNative();
  final accountAddresses = accountAddressesPointer.asTypedList(size);

  return accountAddresses
      .map((addr) => Pointer<AccountRow>.fromAddress(addr).ref)
      .toList();
}

void addAccountSync({required String label}) {
  final labelPointer = label.toNativeUtf8();
  accountAddNewNative(labelPointer);
  calloc.free(labelPointer);
}

void setLabelForAccountSync({required int accountIndex, required String label}) {
  final labelPointer = label.toNativeUtf8();
  accountSetLabelNative(accountIndex, labelPointer);
  calloc.free(labelPointer);
}

void _addAccount(String label) => addAccountSync(label: label);

void _setLabelForAccount(Map<String, dynamic> args) {
  final label = args['label'] as String;
  final accountIndex = args['accountIndex'] as int;

  setLabelForAccountSync(label: label, accountIndex: accountIndex);
}

Future<void> addAccount({required String label}) async {
  await compute(_addAccount, label);
  await store();
}

Future<void> setLabelForAccount({required int accountIndex, required String label}) async {
    await compute(
        _setLabelForAccount, {'accountIndex': accountIndex, 'label': label});
    await store();
}