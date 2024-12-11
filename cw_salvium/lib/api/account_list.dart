import 'package:cw_salvium/api/wallet.dart';
import 'package:monero/monero.dart' as salvium;

salvium.wallet? wptr = null;

int _wlptrForW = 0;
salvium.WalletListener? _wlptr = null;

salvium.WalletListener getWlptr() {
  if (wptr!.address == _wlptrForW) return _wlptr!;
  _wlptrForW = wptr!.address;
  _wlptr = salvium.MONERO_cw_getWalletListener(wptr!);
  return _wlptr!;
}

salvium.SubaddressAccount? subaddressAccount;

bool isUpdating = false;

void refreshAccounts() {
  try {
    isUpdating = true;
    subaddressAccount = salvium.Wallet_subaddressAccount(wptr!);
    salvium.SubaddressAccount_refresh(subaddressAccount!);
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<salvium.SubaddressAccountRow> getAllAccount() {
  // final size = salvium.Wallet_numSubaddressAccounts(wptr!);
  refreshAccounts();
  int size = salvium.SubaddressAccount_getAll_size(subaddressAccount!);
  if (size == 0) {
    salvium.Wallet_addSubaddressAccount(wptr!);
    return getAllAccount();
  }
  return List.generate(size, (index) {
    return salvium.SubaddressAccount_getAll_byIndex(subaddressAccount!,
        index: index);
  });
}

void addAccountSync({required String label}) {
  salvium.Wallet_addSubaddressAccount(wptr!, label: label);
}

void setLabelForAccountSync(
    {required int accountIndex, required String label}) {
  // TODO(mrcyjanek): this may be wrong function?
  salvium.Wallet_setSubaddressLabel(wptr!,
      accountIndex: accountIndex, addressIndex: 0, label: label);
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

Future<void> setLabelForAccount(
    {required int accountIndex, required String label}) async {
  _setLabelForAccount({'accountIndex': accountIndex, 'label': label});
  await store();
}
