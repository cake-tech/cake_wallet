import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';

part 'login_store.g.dart';

abstract class LoginState {}

class InitialLoginState extends LoginState {}

class LoadingCurrentWallet extends LoginState {}

class LoadedCurrentWalletSuccessfully extends LoginState {}

class LoadedCurrentWalletFailure extends LoginState {
  final String errorMessage;

  LoadedCurrentWalletFailure({this.errorMessage});
}

class LoginStore = LoginStoreBase with _$LoginStore;

abstract class LoginStoreBase with Store {
  final SharedPreferences sharedPreferences;
  final WalletListService walletsService;

  @observable
  LoginState state;

  LoginStoreBase(
      {@required this.sharedPreferences, @required this.walletsService}) {
    state = InitialLoginState();
  }

  @action
  Future loadCurrentWallet() async {
    state = InitialLoginState();

    try {
      state = LoadingCurrentWallet();
      final walletName = sharedPreferences.getString('current_wallet_name');
      await walletsService.openWallet(walletName);
      state = LoadedCurrentWalletSuccessfully();
    } catch (e) {
      state = LoadedCurrentWalletFailure(errorMessage: e.toString());
    }
  }
}
