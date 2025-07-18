
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/transaction_history.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:monero/monero.dart';

bool isUpdating = false;

class SubaddressInfoMetadata {
  SubaddressInfoMetadata({
    required this.accountIndex,
  });
  int accountIndex;
}

SubaddressInfoMetadata? subaddress = null;

String getRawLabel({required int accountIndex, required int addressIndex}) {
  return currentWallet?.getSubaddressLabel(accountIndex: accountIndex, addressIndex: addressIndex)??"";
}

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
    required this.received,
    required this.txCount,
  });
  late String address = getAddress(
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  );
  final int addressIndex;
  final int accountIndex;
  final int received;
  final int txCount;
  String get label {
    final localLabel = currentWallet?.getSubaddressLabel(accountIndex: accountIndex, addressIndex: addressIndex) ?? "";
    if (localLabel.startsWith("#$addressIndex")) return localLabel; // don't duplicate the ID if it was user-providen
    return "#$addressIndex ${localLabel}".trim();
  }
}

class TinyTransactionDetails {
  TinyTransactionDetails({
    required this.address,
    required this.amount,
  });
  final List<String> address;
  final int amount;
}

int lastWptr = 0;
int lastTxCount = 0;
List<TinyTransactionDetails> ttDetails = [];

List<Subaddress> getAllSubaddresses() {
  txhistory = currentWallet!.history();
  final txCount = txhistory!.count();
  if (lastTxCount != txCount && lastWptr != currentWallet!.ffiAddress()) {
    final List<TinyTransactionDetails> newttDetails = [];
    lastTxCount = txCount;
    lastWptr = currentWallet!.ffiAddress();
    for (var i = 0; i < txCount; i++) {
      final tx = txhistory!.transaction(i);
      if (tx.direction() == TransactionInfo_Direction.Out.index) continue;
      final subaddrs = tx.subaddrIndex().split(",");
      final account = tx.subaddrAccount();
      newttDetails.add(TinyTransactionDetails(
        address: List.generate(subaddrs.length, (index) => getAddress(accountIndex: account, addressIndex: int.tryParse(subaddrs[index])??0)),
        amount: tx.amount(),
      ));
    }
    ttDetails.clear();
    ttDetails.addAll(newttDetails);
  }
  final size = currentWallet!.numSubaddresses(accountIndex: subaddress!.accountIndex);
  final list = List.generate(size, (index) {
    final ttDetailsLocal = ttDetails.where((element) {
      final address = getAddress(
        accountIndex: subaddress!.accountIndex, 
        addressIndex: index,
      );
      if (element.address.contains(address)) return true;
      return false;
    }).toList();
    int received = 0;
    for (var i = 0; i < ttDetailsLocal.length; i++) {
      received += ttDetailsLocal[i].amount;
    }
    return Subaddress(
      accountIndex: subaddress!.accountIndex,
      addressIndex: index,
      received: received,
      txCount: ttDetailsLocal.length,
    );
  }).reversed.toList();
  if (list.length == 0) {
    list.add(
      Subaddress(
        addressIndex: subaddress!.accountIndex,
        accountIndex: 0,
        received: 0,
        txCount: 0,
      ));
  }
  return list;
}

int numSubaddresses(int subaccountIndex) {
  return currentWallet?.numSubaddresses(accountIndex: subaccountIndex) ?? 0;
}

Future<void> addSubaddress({required int accountIndex, required String label}) async {
  currentWallet?.addSubaddress(accountIndex: accountIndex, label: label);
  refreshSubaddresses(accountIndex: accountIndex);
  await store();
}

Future<void> setLabelForSubaddress(
    {required int accountIndex, required int addressIndex, required String label}) async {
  currentWallet?.setSubaddressLabel(accountIndex: accountIndex, addressIndex: addressIndex, label: label);
  await store();
}