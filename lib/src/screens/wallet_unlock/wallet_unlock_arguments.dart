import 'package:cake_wallet/core/authentication_request_data.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';

typedef AuthPasswordHandler = Future<dynamic> Function(
    String walletName, WalletType walletType, String password);

class WalletUnlockArguments {
  WalletUnlockArguments(
      {required this.callback,
      required this.useTotp,
      this.walletName,
      this.walletType,
      this.authPasswordHandler})
      : state = InitialExecutionState();

  final OnAuthenticationFinished callback;
  final AuthPasswordHandler? authPasswordHandler;
  final String? walletName;
  final WalletType? walletType;
  final bool useTotp;

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
