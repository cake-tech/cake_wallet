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
    required this.txCount,
    required this.received,
  });
  late String address = getAddress(
    accountIndex: accountIndex,
    addressIndex: addressIndex,
  );
  final int addressIndex;
  final int accountIndex;
  String get label => wownero.Wallet_getSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex);
  final int txCount;
  final int received;
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
  txhistory = wownero.Wallet_history(wptr!);
  final txCount = wownero.TransactionHistory_count(txhistory!);
  if (lastTxCount != txCount && lastWptr != wptr!.address) {
    final List<TinyTransactionDetails> newttDetails = [];
    lastTxCount = txCount;
    lastWptr = wptr!.address;
    for (var i = 0; i < txCount; i++) {
      final tx = wownero.TransactionHistory_transaction(txhistory!, index: i);
      final subaddrs = wownero.TransactionInfo_subaddrIndex(tx).split(",");
      final account = wownero.TransactionInfo_subaddrAccount(tx);
      newttDetails.add(TinyTransactionDetails(
        address: List.generate(subaddrs.length, (index) => getAddress(accountIndex: account, addressIndex:  int.tryParse(subaddrs[index])??0)),
        amount: wownero.TransactionInfo_amount(tx),
      ));
    }
    ttDetails.clear();
    ttDetails.addAll(newttDetails);
  }
  final size = wownero.Wallet_numSubaddresses(wptr!, accountIndex: subaddress!.accountIndex);
  final list = List.generate(size, (index) {
    final ttDetailsLocal = ttDetails.where((element) {
      final address = getAddress(
        accountIndex: subaddress!.accountIndex, 
        addressIndex: index,
      );
      if (address == element.address) return true;
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
  if (list.isEmpty) {
    list.add(Subaddress(addressIndex: 0, accountIndex: subaddress!.accountIndex, txCount: 0, received: 0));
  }
  return list;
}

void addSubaddressSync({required int accountIndex, required String label}) {
  wownero.Wallet_addSubaddress(wptr!, accountIndex: accountIndex, label: label);
  refreshSubaddresses(accountIndex: accountIndex);
}

int numSubaddresses(int subaccountIndex) {
  return wownero.Wallet_numSubaddresses(wptr!, accountIndex: subaccountIndex);
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
