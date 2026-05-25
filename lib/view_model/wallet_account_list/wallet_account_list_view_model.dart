import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cw_core/crypto_currency.dart';

abstract class WalletAccountListViewModel {
  List<AccountListItem> get accounts;

  AccountListItem? get selectedAccount;

  CryptoCurrency get currency;

  void select(AccountListItem account);

  void reload();
}
