import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'monero_account_list_view_model.g.dart';

class MoneroAccountListViewModel = MoneroAccountListViewModelBase
    with _$MoneroAccountListViewModel;

abstract class MoneroAccountListViewModelBase with Store {
  MoneroAccountListViewModelBase(this._wallet) : scrollOffsetFromTop = 0;

  @observable
  double scrollOffsetFromTop;

  @action
  void setScrollOffsetFromTop(double scrollOffsetFromTop) {
    this.scrollOffsetFromTop = scrollOffsetFromTop;
  }

  @computed
  List<AccountListItem> get accounts => monero
      .getAccountList(_wallet)
      .accounts.map((acc) => AccountListItem(
          label: acc.label,
          id: acc.id,
          isSelected: acc.id == monero.getCurrentAccount(_wallet).id))
      .toList();

  final WalletBase _wallet;

  void select(AccountListItem item) =>
      monero.setCurrentAccount(
        _wallet,
        Account(
          id: item.id,
          label: item.label));
}
