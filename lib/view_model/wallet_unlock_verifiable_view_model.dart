import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/wallet_unlock_view_model.dart';

part 'wallet_unlock_verifiable_view_model.g.dart';

class WalletUnlockVerifiableViewModel = WalletUnlockVerifiableViewModelBase
    with _$WalletUnlockVerifiableViewModel;

abstract class WalletUnlockVerifiableViewModelBase extends WalletUnlockViewModel with Store {
  WalletUnlockVerifiableViewModelBase(this.appStore,
      {required this.walletName, required this.walletType})
      : password = '',
        state = InitialExecutionState();

  final String walletName;

  final WalletType walletType;

  final AppStore appStore;

  @override
  @observable
  String password;

  @override
  @observable
  ExecutionState state;

  @override
  @action
  void setPassword(String password) => this.password = password;

  @override
  @action
  Future<void> unlock() async {
    try {
      state = appStore.wallet!.password == password
          ? ExecutedSuccessfullyState()
          : FailureState(S.current.invalid_password);
    } catch (e) {
      failure('${S.current.invalid_password}\n${e.toString()}');
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
