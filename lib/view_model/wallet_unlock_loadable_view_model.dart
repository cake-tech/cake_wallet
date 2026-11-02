import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/wallet_unlock_view_model.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";

part "wallet_unlock_loadable_view_model.g.dart";

class WalletUnlockLoadableViewModel = WalletUnlockLoadableViewModelBase
    with _$WalletUnlockLoadableViewModel;

abstract class WalletUnlockLoadableViewModelBase extends WalletUnlockViewModel with Store {
  WalletUnlockLoadableViewModelBase(this._appStore, this._walletLoadingService,
      {required this.walletName, required this.walletType})
      : password = '',
        state = InitialExecutionState();

  final String walletName;

  final WalletType walletType;

  @override
  @observable
  String password;

  @override
  @observable
  ExecutionState state;

  final WalletLoadingService _walletLoadingService;

  final AppStore _appStore;

  @override
  @action
  void setPassword(String password) => this.password = password;

  @override
  @action
  Future<void> unlock() async {
    try {
      state = InitialExecutionState();

      // TODO(wallet-id): name + type is ambiguous for UUID wallets; pass the wallet id instead.
      final walletInfo = await WalletInfo.get(walletName, walletType);
      if (walletInfo == null) {
        throw WalletNotFoundException(name: walletName, type: walletType);
      }

      final wallet = await _walletLoadingService.load(walletInfo, password: password);
      _appStore.changeCurrentWallet(wallet);
      success();
    } catch (e) {
      failure(e.toString());
    }
  }

  @override
  @action
  void success() {
    state = ExecutedSuccessfullyState();
  }

  @override
  @action
  void failure(e) {
    state = FailureState(e.toString());
  }
}
