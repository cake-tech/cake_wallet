import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/view_model/auth_state.dart';
import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/entities/biometric_auth.dart';
import 'package:cake_wallet/store/settings_store.dart';

part 'auth_view_model.g.dart';

class AuthViewModel = AuthViewModelBase with _$AuthViewModel;

abstract class AuthViewModelBase with Store {
  AuthViewModelBase(
      this._authService, this._sharedPreferences, this._settingsStore, this._biometricAuth)
      : _failureCounter = 0,
        state = InitialExecutionState() {
    reaction((_) => state, _saveLastAuthTime);
  }

  static const maxFailedLogins = 3;
  static const banTimeout = 180; // 3 minutes
  final banTimeoutKey = S.current.auth_store_ban_timeout;

  @observable
  ExecutionState state;

  int get pinLength => _settingsStore.pinCodeLength;

  bool get isBiometricalAuthenticationAllowed => _settingsStore.allowBiometricalAuthentication;

  @observable
  int _failureCounter;

  final AuthService _authService;
  final BiometricAuth _biometricAuth;
  final SharedPreferences _sharedPreferences;
  final SettingsStore _settingsStore;

  @action
  Future<void> auth({required String password}) async {
    state = InitialExecutionState();
    final _banDuration = banDuration();

    if (_banDuration != null) {
      state = AuthenticationBanned(
          error: S.current.auth_store_banned_for +
              '${_banDuration.inMinutes}' +
              S.current.auth_store_banned_minutes);
      return;
    }

    state = IsExecutingState();
    final isSuccessfulAuthenticated = await _authService.authenticate(password);

    if (isSuccessfulAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        state = ExecutedSuccessfullyState();
        _failureCounter = 0;
      });
    } else {
      _failureCounter += 1;

      if (_failureCounter >= maxFailedLogins) {
        final banDuration = await ban();
        state = AuthenticationBanned(
            error: S.current.auth_store_banned_for +
                '${banDuration.inMinutes}' +
                S.current.auth_store_banned_minutes);
        return;
      }

      state = FailureState(S.current.auth_store_incorrect_password);
    }
  }

  Duration? banDuration() {
    final unbanTimestamp = _sharedPreferences.getInt(banTimeoutKey);

    if (unbanTimestamp == null) {
      return null;
    }

    final unbanTime = DateTime.fromMillisecondsSinceEpoch(unbanTimestamp);
    final now = DateTime.now();

    if (now.isAfter(unbanTime)) {
      return null;
    }

    return Duration(milliseconds: unbanTimestamp - now.millisecondsSinceEpoch);
  }

  Future<Duration> ban() async {
    final multiplier = _failureCounter - maxFailedLogins + 1;
    final timeout = (multiplier * banTimeout) * 1000;
    final unbanTimestamp = DateTime.now().millisecondsSinceEpoch + timeout;
    await _sharedPreferences.setInt(banTimeoutKey, unbanTimestamp);

    return Duration(milliseconds: timeout);
  }

  @action
  Future<void> biometricAuth() async {
    try {
      final canBiometricAuth = await _biometricAuth.canCheckBiometrics();

      if (canBiometricAuth) {
        final isAuthenticated = await _biometricAuth.isAuthenticated();

        if (isAuthenticated) {
          state = ExecutedSuccessfullyState();
        }
      }
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  void _saveLastAuthTime(ExecutionState state) {
    if (state is ExecutedSuccessfullyState) {
      _authService.saveLastAuthTime();
    }
  }
}
