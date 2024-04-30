import 'package:cake_wallet/nano/nano.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/nano_account.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';

part 'nano_account_list_view_model.g.dart';

class NanoAccountListViewModel = NanoAccountListViewModelBase with _$NanoAccountListViewModel;

abstract class NanoAccountListViewModelBase with Store {
  NanoAccountListViewModelBase(this._wallet) : scrollOffsetFromTop = 0;

  @observable
  double scrollOffsetFromTop;

  @action
  void setScrollOffsetFromTop(double scrollOffsetFromTop) {
    this.scrollOffsetFromTop = scrollOffsetFromTop;
  }

  CryptoCurrency get currency => _wallet.currency;

  @computed
  List<NanoAccount> get accounts {
    if (_wallet.type == WalletType.nano) {
      return nano!
          .getAccountList(_wallet)
          .accounts
          .map((acc) => NanoAccount(
                label: acc.label,
                id: acc.id,
                isSelected: acc.id == nano?.getCurrentAccount(_wallet).id,
              ))
          .toList();
    }

    throw Exception('Unexpected wallet type: ${_wallet.type}');
  }

  final WalletBase _wallet;

  void select(NanoAccount item) {
    if (_wallet.type == WalletType.nano) {
      nano!.setCurrentAccount(
        _wallet,
        item.id,
        item.label,
        item.balance,
      );
    }
  }
}
