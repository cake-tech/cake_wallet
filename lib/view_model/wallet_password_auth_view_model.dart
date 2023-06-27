import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/view_model/wallet_unlock_view_model.dart';

part 'wallet_password_auth_view_model.g.dart';

class WalletPasswordAuthViewModel = WalletPasswordAuthViewModelBase
    with _$WalletPasswordAuthViewModel;

abstract class WalletPasswordAuthViewModelBase extends WalletUnlockViewModel
    with Store {
  WalletPasswordAuthViewModelBase(this._walletLoadingService,
      {required this.walletName, required this.walletType})
      : state = InitialExecutionState();

  final String walletName;

  final WalletType walletType;

  @override
  @observable
  String? password;

  @override
  @observable
  ExecutionState state;

  final WalletLoadingService _walletLoadingService;

  @override
  @action
  void setPassword(String password) => this.password = password;

  @override
  @action
  Future<dynamic> unlock({String? walletName, WalletType? walletType}) async {
    try {
      state = InitialExecutionState();
      final wallet = await _walletLoadingService.load(
          walletType ?? this.walletType, walletName ?? this.walletName,
          password: password);

      return wallet;
    } catch (e) {
      state = FailureState(e.toString());
      return null;
    }
  }

  void success() {
    state = ExecutedSuccessfullyState();
  }
}
