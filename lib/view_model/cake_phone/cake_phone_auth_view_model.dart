import 'dart:async';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/providers/cake_phone_provider.dart';
import 'package:cake_wallet/core/execution_state.dart';

part 'cake_phone_auth_view_model.g.dart';

class CakePhoneAuthViewModel = CakePhoneAuthViewModelBase with _$CakePhoneAuthViewModel;

abstract class CakePhoneAuthViewModelBase with Store {
  CakePhoneAuthViewModelBase(this._cakePhoneProvider, this._secureStorage) {
    state = InitialExecutionState();
  }

  @observable
  ExecutionState state;

  final CakePhoneProvider _cakePhoneProvider;
  final FlutterSecureStorage _secureStorage;

  bool _userExists = false;
  String _email = "";

  @action
  Future<void> auth(String email) async {
    state = IsExecutingState();

    final result = await _cakePhoneProvider.authenticate(email);

    result.fold(
      (failure) => state = FailureState(failure.errorMessage),
      (userExists) {
        _userExists = userExists;
        _email = email;
        state = ExecutedSuccessfullyState();
      },
    );
  }

  @action
  Future<void> verify(String code) async {
    final result = await _cakePhoneProvider.verifyEmail(email: _email, code: code);

    result.fold(
      (failure) => state = FailureState(failure.errorMessage),
      (token) {
        _secureStorage.write(key: PreferencesKey.cakePhoneTokenKey, value: token);
        state = ExecutedSuccessfullyState(payload: _userExists);
      },
    );
  }
}
