
import 'dart:async';

import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/transaction_history.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:monero/monero.dart' as monero;

bool isUpdating = false;

class SubaddressInfoMetadata {
  SubaddressInfoMetadata({
    required this.accountIndex,
  });
  int accountIndex;
}

SubaddressInfoMetadata? subaddress = null;

void refreshSubaddresses({required int accountIndex}) {
  try {
    isUpdating = true;
    subaddress = SubaddressInfoMetadata(accountIndex: accountIndex);
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

class Subaddress {
  Subaddress({
    required this.addressIndex,
    required this.accountIndex,
  });
  String get address => monero.Wallet_address(
        wptr!,
        accountIndex: accountIndex,
        addressIndex: addressIndex,
    );
  final int addressIndex;
  final int accountIndex;
  String get label => monero.Wallet_getSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex);
}

List<Subaddress> getAllSubaddresses() {
  final size = monero.Wallet_numSubaddresses(wptr!, accountIndex: subaddress!.accountIndex);
  final list = List.generate(size, (index) {
    return Subaddress(
      accountIndex: subaddress!.accountIndex,
      addressIndex: index,
    );
  }).reversed.toList();
  if (list.length == 0) {
    list.add(Subaddress(addressIndex: subaddress!.accountIndex, accountIndex: 0));
  }
  return list;
}

void addSubaddressSync({required int accountIndex, required String label}) {
  monero.Wallet_addSubaddress(wptr!, accountIndex: accountIndex, label: label);
  refreshSubaddresses(accountIndex: accountIndex);
}

void setLabelForSubaddressSync(
    {required int accountIndex, required int addressIndex, required String label}) {
  monero.Wallet_setSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex, label: label);
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

Future<void> addSubaddress({required int accountIndex, required String label}) async {
  _addSubaddress({'accountIndex': accountIndex, 'label': label});
  await store();
}

Future<void> setLabelForSubaddress(
        {required int accountIndex, required int addressIndex, required String label}) async {
  _setLabelForSubaddress({
    'accountIndex': accountIndex,
    'addressIndex': addressIndex,
    'label': label
  });
  await store();
}


List<String> cachedAddresses = [];
int cachedTxCount = 0;
int cachedWptrAddress = 0;
List<String> getUsedAddrsses() {
  List<String> addresses = [];
  txhistory ??= monero.Wallet_history(wptr!);
  int size = countOfTransactions();
  if (cachedTxCount == size && cachedWptrAddress == wptr!.address) {
    return cachedAddresses;
  }
  if (txHistoryMutex.isLocked) return cachedAddresses;
  unawaited(txHistoryMutex.acquire()); // I KNOW

  for (var i = 0; i < size; i++) {
    final txPtr = monero.TransactionHistory_transaction(txhistory!, index: i);
    final subaddrAccount = monero.TransactionInfo_subaddrAccount(txPtr);
    final subaddrAddress = monero.TransactionInfo_subaddrIndex(txPtr).split(", ").map((e) => int.tryParse(e)??0).toList();
    for (var j = 0; j < subaddrAddress.length; j++) {
      addresses.add(
        getAddress(
          accountIndex: subaddrAccount,
          addressIndex: subaddrAddress[j],
        )
      );
    }
  }
  cachedAddresses.addAll(addresses);
  cachedTxCount = size;
  cachedWptrAddress = wptr!.address;
  txHistoryMutex.release();
  return addresses;
}