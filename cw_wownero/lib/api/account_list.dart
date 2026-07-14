import 'package:cw_wownero/api/wallet.dart';
import 'package:monero/wownero.dart' as wownero;

wownero.wallet? wptr = null;

int _wlptrForW = 0;
wownero.WalletListener? _wlptr = null;

wownero.WalletListener getWlptr() {
  if (wptr!.address == _wlptrForW) return _wlptr!;
  _wlptrForW = wptr!.address;
  _wlptr = wownero.WOWNERO_cw_getWalletListener(wptr!);
  return _wlptr!;
}


wownero.SubaddressAccount? subaddressAccount;

bool isUpdating = false;

void refreshAccounts() {
  if (wptr == null) return;

  try {
    isUpdating = true;
    subaddressAccount = wownero.Wallet_subaddressAccount(wptr!);
    wownero.SubaddressAccount_refresh(subaddressAccount!);
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<wownero.SubaddressAccountRow> getAllAccount() {
  if (wptr == null) return [];
  // final size = wownero.Wallet_numSubaddressAccounts(wptr!);
  refreshAccounts();
  int size = wownero.SubaddressAccount_getAll_size(subaddressAccount!);
  if (size == 0) {
    wownero.Wallet_addSubaddressAccount(wptr!);
    return getAllAccount();
  }
  return List.generate(size, (index) {
    return wownero.SubaddressAccount_getAll_byIndex(subaddressAccount!, index: index);
  });
}

void addAccountSync({required String label}) {
  wownero.Wallet_addSubaddressAccount(wptr!, label: label);
}

void setLabelForAccountSync({required int accountIndex, required String label}) {
  wownero.SubaddressAccount_setLabel(subaddressAccount!, accountIndex: accountIndex, label: label);
}

void _addAccount(String label) => addAccountSync(label: label);

void _setLabelForAccount(Map<String, dynamic> args) {
  final label = args['label'] as String;
  final accountIndex = args['accountIndex'] as int;

  setLabelForAccountSync(label: label, accountIndex: accountIndex);
}

Future<void> addAccount({required String label}) async {
  _addAccount(label);
  await store();
}

Future<void> setLabelForAccount({required int accountIndex, required String label}) async {
    _setLabelForAccount({'accountIndex': accountIndex, 'label': label});
    await store();
}