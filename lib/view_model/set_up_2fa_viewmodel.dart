// ignore_for_file: prefer_final_fields

import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/totp_utils.dart' as Utils;
import 'package:cake_wallet/view_model/auth_state.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth_service.dart';
import '../core/execution_state.dart';
import '../generated/i18n.dart';

part 'set_up_2fa_viewmodel.g.dart';

class Setup2FAViewModel = Setup2FAViewModelBase with _$Setup2FAViewModel;

abstract class Setup2FAViewModelBase with Store {
  final SettingsStore _settingsStore;
  final AuthService _authService;
  final SharedPreferences _sharedPreferences;

  Setup2FAViewModelBase(this._settingsStore, this._sharedPreferences, this._authService)
      : _failureCounter = 0,
        enteredOTPCode = '',
        state = InitialExecutionState() {
    _getRandomBase32SecretKey();
    reaction((_) => state, _saveLastAuthTime);
  }

  static const maxFailedTrials = 3;
  static const banTimeout = 180; // 3 minutes
  final banTimeoutKey = S.current.auth_store_ban_timeout;

  String get secretKey => _settingsStore.totpSecretKey;
  String get deviceName => _settingsStore.deviceName;
  String get totpVersionOneLink => _settingsStore.totpVersionOneLink;

  @observable
  ExecutionState state;

  @observable
  int _failureCounter;

  @observable
  String enteredOTPCode;

  @computed
  bool get useTOTP2FA => _settingsStore.useTOTP2FA;

  void _getRandomBase32SecretKey() {
    final randomBase32Key = Utils.generateRandomBase32SecretKey(16);
    _setBase32SecretKey(randomBase32Key);
  }

  @action
  void setUseTOTP2FA(bool value) {
    _settingsStore.useTOTP2FA = value;
  }

  @action
  void _setBase32SecretKey(String value) {
    if (_settingsStore.totpSecretKey == '') {
      _settingsStore.totpSecretKey = value;
    }
  }

  @action
  void clearBase32SecretKey() {
    _settingsStore.totpSecretKey = '';
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
    final multiplier = _failureCounter - maxFailedTrials;
    final timeout = (multiplier * banTimeout) * 1000;
    final unbanTimestamp = DateTime.now().millisecondsSinceEpoch + timeout;
    await _sharedPreferences.setInt(banTimeoutKey, unbanTimestamp);

    return Duration(milliseconds: timeout);
  }

  @action
  Future<bool> totp2FAAuth(String otpText, bool isForSetup) async {
    state = InitialExecutionState();
    _failureCounter = _settingsStore.numberOfFailedTokenTrials;
    final _banDuration = banDuration();

    if (_banDuration != null) {
      state = AuthenticationBanned(
          error: S.current.auth_store_banned_for +
              '${_banDuration.inMinutes}' +
              S.current.auth_store_banned_minutes);
      return false;
    }

    final result = Utils.verify(
      secretKey: secretKey,
      otp: otpText,
    );

    isForSetup ? setUseTOTP2FA(result) : null;

    if (result) {
      return true;
    } else {
      final value = _settingsStore.numberOfFailedTokenTrials + 1;
      adjustTokenTrialNumber(value);
      print(value);
      if (_failureCounter >= maxFailedTrials) {
        final banDuration = await ban();
        state = AuthenticationBanned(
            error: S.current.auth_store_banned_for +
                '${banDuration.inMinutes}' +
                S.current.auth_store_banned_minutes);
        return false;
      }

      state = FailureState('Incorrect code');
      return false;
    }
  }

  @action
  void success() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      state = ExecutedSuccessfullyState();
      adjustTokenTrialNumber(0);
    });
  }

  @action
  void adjustTokenTrialNumber(int value) {
    _failureCounter = value;
    _settingsStore.numberOfFailedTokenTrials = value;
  }

  void _saveLastAuthTime(ExecutionState state) {
    if (state is ExecutedSuccessfullyState) {
      _authService.saveLastAuthTime();
    }
  }
}
