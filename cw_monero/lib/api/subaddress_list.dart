import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/wallet.dart';
import 'package:monero/monero.dart' as monero;

bool isUpdating = false;
monero.Subaddress? subaddressPtr = null;
void refreshSubaddresses({required int accountIndex}) {
  try {
    isUpdating = true;
    subaddressPtr = monero.Wallet_subaddress(wptr!);
    monero.Subaddress_refresh(subaddressPtr!,accountIndex: accountIndex, label: '');
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<monero.SubaddressRow> getAllSubaddresses() {
  monero.Subaddress_refresh(subaddressPtr!, 
  accountIndex: 0,
  label: '' // BUG: by me (mrcyjanek), it isn't used, will remove.
  );
  final size = monero.Subaddress_getAll_size(subaddressPtr!);


  return List.generate(size, (index) {
    return monero.Subaddress_getAll_byIndex(subaddressAccount!, index: index);
  });
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
