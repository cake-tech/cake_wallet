import 'package:cw_nerva/api/wallet.dart';
import 'package:monero/nerva.dart' as nerva;

nerva.wallet? wptr = null;

int _wlptrForW = 0;
nerva.WalletListener? _wlptr = null;

nerva.WalletListener getWlptr() {
  if (wptr!.address == _wlptrForW) return _wlptr!;
  _wlptrForW = wptr!.address;
  _wlptr = nerva.NERVA_cw_getWalletListener(wptr!);
  return _wlptr!;
}


nerva.SubaddressAccount? subaddressAccount;

bool isUpdating = false;

void refreshAccounts() {
  if (wptr == null) return;

  try {
    isUpdating = true;
    subaddressAccount = nerva.Wallet_subaddressAccount(wptr!);
    nerva.SubaddressAccount_refresh(subaddressAccount!);
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<nerva.SubaddressAccountRow> getAllAccount() {
  if (wptr == null) return [];
  // final size = nerva.Wallet_numSubaddressAccounts(wptr!);
  refreshAccounts();
  int size = nerva.SubaddressAccount_getAll_size(subaddressAccount!);
  if (size == 0) {
    nerva.Wallet_addSubaddressAccount(wptr!);
    return getAllAccount();
  }
  return List.generate(size, (index) {
    return nerva.SubaddressAccount_getAll_byIndex(subaddressAccount!, index: index);
  });
}

void addAccountSync({required String label}) {
  nerva.Wallet_addSubaddressAccount(wptr!, label: label);
}

void setLabelForAccountSync({required int accountIndex, required String label}) {
  nerva.SubaddressAccount_setLabel(subaddressAccount!, accountIndex: accountIndex, label: label);
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