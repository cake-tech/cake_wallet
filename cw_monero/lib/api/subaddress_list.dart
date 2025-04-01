
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

String getRawLabel({required int accountIndex, required int addressIndex}) {
  return monero.Wallet_getSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex);
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
    final localLabel = monero.Wallet_getSubaddressLabel(wptr!, accountIndex: accountIndex, addressIndex: addressIndex);
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
  txhistory = monero.Wallet_history(wptr!);
  final txCount = monero.TransactionHistory_count(txhistory!);
  if (lastTxCount != txCount && lastWptr != wptr!.address) {
    final List<TinyTransactionDetails> newttDetails = [];
    lastTxCount = txCount;
    lastWptr = wptr!.address;
    for (var i = 0; i < txCount; i++) {
      final tx = monero.TransactionHistory_transaction(txhistory!, index: i);
      if (monero.TransactionInfo_direction(tx) == monero.TransactionInfo_Direction.Out) continue;
      final subaddrs = monero.TransactionInfo_subaddrIndex(tx).split(",");
      final account = monero.TransactionInfo_subaddrAccount(tx);
      newttDetails.add(TinyTransactionDetails(
        address: List.generate(subaddrs.length, (index) => getAddress(accountIndex: account, addressIndex: int.tryParse(subaddrs[index])??0)),
        amount: monero.TransactionInfo_amount(tx),
      ));
    }
    ttDetails.clear();
    ttDetails.addAll(newttDetails);
  }
  final size = monero.Wallet_numSubaddresses(wptr!, accountIndex: subaddress!.accountIndex);
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
  return monero.Wallet_numSubaddresses(wptr!, accountIndex: subaccountIndex);
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
