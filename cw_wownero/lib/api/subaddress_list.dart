import 'dart:async';

import 'package:cw_wownero/api/account_list.dart';
import 'package:cw_wownero/api/transaction_history.dart';
import 'package:cw_wownero/api/wallet.dart';
import 'package:monero/wownero.dart' as wownero;

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
  String get address => wownero.Wallet_address(
        wptr!,
        accountIndex: accountIndex,
        addressIndex: addressIndex,
    );
  final int addressIndex;
  final int accountIndex;
  String get label => wownero.Wallet_getSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex);
}

List<Subaddress> getAllSubaddresses() {
  final size = wownero.Wallet_numSubaddresses(wptr!, accountIndex: subaddress!.accountIndex);
  final list = List.generate(size, (index) {
    return Subaddress(
      accountIndex: subaddress!.accountIndex,
      addressIndex: index,
    );
  }).reversed.toList();
  if (list.isEmpty) {
    list.add(Subaddress(addressIndex: 0, accountIndex: subaddress!.accountIndex));
  }
  return list;
}

void addSubaddressSync({required int accountIndex, required String label}) {
  wownero.Wallet_addSubaddress(wptr!, accountIndex: accountIndex, label: label);
  refreshSubaddresses(accountIndex: accountIndex);
}

void setLabelForSubaddressSync(
    {required int accountIndex, required int addressIndex, required String label}) {
  wownero.Wallet_setSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex, label: label);
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
  txhistory ??= wownero.Wallet_history(wptr!);
  int size = countOfTransactions();
  if (cachedTxCount == size && cachedWptrAddress == wptr!.address) {
    return cachedAddresses;
  }
  if (txHistoryMutex.isLocked) return cachedAddresses;
  unawaited(txHistoryMutex.acquire()); // I KNOW
  final Stopwatch stopwatch = Stopwatch()..start();

  for (var i = 0; i < size; i++) {
    final txPtr = wownero.TransactionHistory_transaction(txhistory!, index: i);
    final subaddrAccount = wownero.TransactionInfo_subaddrAccount(txPtr);
    final subaddrAddress = wownero.TransactionInfo_subaddrIndex(txPtr).split(", ").map((e) => int.tryParse(e)??0).toList();
    for (var j = 0; j < subaddrAddress.length; j++) {
      addresses.add(
        getAddress(
          accountIndex: subaddrAccount,
          addressIndex: subaddrAddress[j],
        )
      );
    }
  }
  cachedAddresses.clear();
  cachedAddresses.addAll(addresses);
  cachedTxCount = size;
  cachedWptrAddress = wptr!.address;
  txHistoryMutex.release();
  wownero.debugCallLength["CW_getUsedAddrsses"] ??= <int>[];
  wownero.debugCallLength["CW_getUsedAddrsses"]!.add(stopwatch!.elapsedMicroseconds);
  return addresses;
}