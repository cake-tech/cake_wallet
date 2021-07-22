import 'package:mobx/mobx.dart';
import 'package:cake_wallet/monero/account.dart';
import 'package:cake_wallet/monero/monero_wallet.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';

part 'monero_account_list_view_model.g.dart';

class MoneroAccountListViewModel = MoneroAccountListViewModelBase
    with _$MoneroAccountListViewModel;

abstract class MoneroAccountListViewModelBase with Store {
  MoneroAccountListViewModelBase(this._moneroWallet) : scrollOffsetFromTop = 0;

  @observable
  double scrollOffsetFromTop;

  @action
  void setScrollOffsetFromTop(double scrollOffsetFromTop) {
    this.scrollOffsetFromTop = scrollOffsetFromTop;
  }

  @computed
  List<AccountListItem> get accounts => _moneroWallet.walletAddresses
      .accountList.accounts.map((acc) => AccountListItem(
          label: acc.label,
          id: acc.id,
          isSelected: acc.id == _moneroWallet.walletAddresses.account.id))
      .toList();

  final MoneroWallet _moneroWallet;

  void select(AccountListItem item) =>
      _moneroWallet.walletAddresses.account =
          Account(id: item.id, label: item.label);
}
