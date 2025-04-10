import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/view_model/monero_account_list/account_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'monero_account_list_view_model.g.dart';

class MoneroAccountListViewModel = MoneroAccountListViewModelBase with _$MoneroAccountListViewModel;

abstract class MoneroAccountListViewModelBase with Store {
  MoneroAccountListViewModelBase(this._wallet) : scrollOffsetFromTop = 0;

  @observable
  double scrollOffsetFromTop;

  @action
  void setScrollOffsetFromTop(double scrollOffsetFromTop) {
    this.scrollOffsetFromTop = scrollOffsetFromTop;
  }

  CryptoCurrency get currency => _wallet.currency;

  @computed
  List<AccountListItem> get accounts {
    if (_wallet.type == WalletType.monero) {
      var accList = monero!
          .getAccountList(_wallet)
          .accounts
          .map((acc) => AccountListItem(
              label: acc.label,
              id: acc.id,
              balance: acc.balance,
              isSelected: acc.id == monero!.getCurrentAccount(_wallet).id))
          .toList();

      final subList = monero!
          .getSubaddressList(_wallet)
          .subaddresses
          .map((acc) => AccountListItem(
              label: acc.label,
              id: acc.id,
              balance: '0',
              isSelected: acc.id == monero!.getCurrentAccount(_wallet).id))
          .toList();

      // override the labels of the accList with the labels of the subList
      // this is needed because the function to update the labels doesn't update the same labels in the account list
      // and there doesn't appear to be an equivalent account label function
      final newAccList = accList.map((acc) {
        try {
          var subLabel = subList.firstWhere((sub) => sub.id == acc.id).label;
          // remove everything before the first space:
          subLabel = subLabel.split(' ').last;
          return AccountListItem(
            label: subLabel,
            id: acc.id,
            balance: acc.balance,
            isSelected: acc.id == monero!.getCurrentAccount(_wallet).id,
          );
        } catch (e) {
          return acc;
        }
      }).toList();

      return newAccList;
    }

    if (_wallet.type == WalletType.wownero) {
      var accList = wownero!
          .getAccountList(_wallet)
          .accounts
          .map((acc) => AccountListItem(
              label: acc.label,
              id: acc.id,
              balance: acc.balance,
              isSelected: acc.id == wownero!.getCurrentAccount(_wallet).id))
          .toList();

      final subList = wownero!
          .getSubaddressList(_wallet)
          .subaddresses
          .map((acc) => AccountListItem(
              label: acc.label,
              id: acc.id,
              balance: '0',
              isSelected: acc.id == wownero!.getCurrentAccount(_wallet).id))
          .toList();

      // override the labels of the accList with the labels of the subList
      // this is needed because the function to update the labels doesn't update the same labels in the account list
      // and there doesn't appear to be an equivalent account label function
      final newAccList = accList.map((acc) {
        try {
          var subLabel = subList.firstWhere((sub) => sub.id == acc.id).label;
          // remove everything before the first space:
          subLabel = subLabel.split(' ').last;
          return AccountListItem(
            label: subLabel,
            id: acc.id,
            balance: acc.balance,
            isSelected: acc.id == wownero!.getCurrentAccount(_wallet).id,
          );
        } catch (e) {
          return acc;
        }
      }).toList();

      return newAccList;
    }

    throw Exception('Unexpected wallet type: ${_wallet.type}');
  }

  final WalletBase _wallet;

  void select(AccountListItem item) {
    if (_wallet.type == WalletType.monero) {
      monero!.setCurrentAccount(
        _wallet,
        item.id,
        item.label,
        item.balance,
      );
    }

    if (_wallet.type == WalletType.wownero) {
      wownero!.setCurrentAccount(
        _wallet,
        item.id,
        item.label,
        item.balance,
      );
    }
  }
}
