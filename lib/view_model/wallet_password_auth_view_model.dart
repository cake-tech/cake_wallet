import 'package:cake_wallet/core/execution_state.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'wallet_password_auth_view_model.g.dart';

class WalletPasswordAuthViewModel = WalletPasswordAuthViewModelBase
    with _$WalletPasswordAuthViewModel;

abstract class WalletPasswordAuthViewModelBase with Store {
  WalletPasswordAuthViewModelBase(
      {required this.useTotp, required this.walletName, required this.walletType})
      : password = '',
        state = InitialExecutionState();

  @observable
  String walletName;
  @observable
  WalletType walletType;
  @observable
  String password;
  @observable
  bool useTotp;

  @action
  void setPassword(String password) => this.password = password;

  @observable
  ExecutionState state;

  @action
  void success() {
    state = ExecutedSuccessfullyState();
  }

  @action
  void failure(e) {
    state = FailureState(e.toString());
  }
}
