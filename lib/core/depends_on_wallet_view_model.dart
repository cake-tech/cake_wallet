import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/store/app_store.dart';

part 'depends_on_wallet_view_model.g.dart';

class DependsOnWalletViewModel = DependsOnWalletViewModelBase with _$DependsOnWalletViewModel;

abstract class DependsOnWalletViewModelBase with Store {
  DependsOnWalletViewModelBase({
    required AppStore appStore,
  }) : _wallet = appStore.wallet! {
    reaction((_) => appStore.wallet, (WalletBase? wallet) {
      _wallet = wallet!;
      onWalletChange(wallet);
    });
  }

  void onWalletChange(WalletBase wallet) {}

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;
  @computed
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> get wallet =>
      _wallet;
}
