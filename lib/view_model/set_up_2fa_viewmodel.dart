// ignore_for_file: prefer_final_fields

import 'package:cake_wallet/entities/cake_2fa_preset_options.dart';
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
        unhighlightTabs = false,
        selected2FASettings = ObservableList<VerboseControlSettings>(),
        state = InitialExecutionState() {
    _getRandomBase32SecretKey();
    selectCakePreset(selectedCake2FAPreset);
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

  @computed
  bool get shouldRequireTOTP2FAForAccessingWallet =>
      _settingsStore.shouldRequireTOTP2FAForAccessingWallet;

  @computed
  bool get shouldRequireTOTP2FAForSendsToContact =>
      _settingsStore.shouldRequireTOTP2FAForSendsToContact;

  @computed
  bool get shouldRequireTOTP2FAForSendsToNonContact =>
      _settingsStore.shouldRequireTOTP2FAForSendsToNonContact;

  @computed
  bool get shouldRequireTOTP2FAForSendsToInternalWallets =>
      _settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets;

  @computed
  bool get shouldRequireTOTP2FAForExchangesToInternalWallets =>
      _settingsStore.shouldRequireTOTP2FAForExchangesToInternalWallets;

  @computed
  bool get shouldRequireTOTP2FAForAddingContacts =>
      _settingsStore.shouldRequireTOTP2FAForAddingContacts;

  @computed
  bool get shouldRequireTOTP2FAForCreatingNewWallets =>
      _settingsStore.shouldRequireTOTP2FAForCreatingNewWallets;

  @computed
  bool get shouldRequireTOTP2FAForAllSecurityAndBackupSettings =>
      _settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings;

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

  @computed
  Cake2FAPresetsOptions get selectedCake2FAPreset => _settingsStore.selectedCake2FAPreset;

  @observable
  bool unhighlightTabs = false;

  @observable
  ObservableList<VerboseControlSettings> selected2FASettings;

  //! The code here works, but can be improved
  //! Still trying out various ways to improve it
  @action
  void selectCakePreset(Cake2FAPresetsOptions cake2FAPreset) {
    // The tabs are ordered in the format [Narrow || Normal || Verbose]
    // Where Narrow = 0, Normal = 1 and Verbose =  2
    switch (cake2FAPreset) {
      case Cake2FAPresetsOptions.narrow:
        activateCake2FANarrowPreset();
        break;
      case Cake2FAPresetsOptions.normal:
        activateCake2FANormalPreset();
        break;
      case Cake2FAPresetsOptions.aggressive:
        activateCake2FAAggressivePreset();
        break;
      default:
        activateCake2FANormalPreset();
    }
  }

  @action
  void checkIfTheCurrentSettingMatchesAnyOfThePresets() {
    final hasNormalPreset = checkIfTheNormalPresetIsPresent();
    final hasNarrowPreset = checkIfTheNarrowPresetIsPresent();
    final hasVerbosePreset = checkIfTheVerbosePresetIsPresent();

    if (hasNormalPreset || hasNarrowPreset || hasVerbosePreset) {
      unhighlightTabs = false;
    } else {
      unhighlightTabs = true;
    }
  }

  @action
  bool checkIfTheNormalPresetIsPresent() {
    final hasContacts = selected2FASettings.contains(VerboseControlSettings.sendsToContacts);
    final hasNonContacts = selected2FASettings.contains(VerboseControlSettings.sendsToNonContacts);
    final hasSecurityAndBackup =
        selected2FASettings.contains(VerboseControlSettings.securityAndBackupSettings);

    final hasSendToInternalWallet =
        selected2FASettings.contains(VerboseControlSettings.sendsToInternalWallets);

    final hasExchangesToInternalWallet =
        selected2FASettings.contains(VerboseControlSettings.exchangesToInternalWallets);

    bool isOnlyNormalPresetControlsPresent = selected2FASettings.length == 5;

    return (hasContacts &&
        hasNonContacts &&
        hasSecurityAndBackup &&
        hasSendToInternalWallet &&
        hasExchangesToInternalWallet &&
        isOnlyNormalPresetControlsPresent);
  }

  @action
  bool checkIfTheVerbosePresetIsPresent() {
    final hasAccessWallets = selected2FASettings.contains(VerboseControlSettings.accessWallet);
    final hasSecurityAndBackup =
        selected2FASettings.contains(VerboseControlSettings.securityAndBackupSettings);

    bool isOnlyVerbosePresetControlsPresent = selected2FASettings.length == 2;

    return (hasAccessWallets && hasSecurityAndBackup && isOnlyVerbosePresetControlsPresent);
  }

  @action
  bool checkIfTheNarrowPresetIsPresent() {
    final hasNonContacts = selected2FASettings.contains(VerboseControlSettings.sendsToNonContacts);
    final hasAddContacts = selected2FASettings.contains(VerboseControlSettings.addingContacts);
    final hasCreateNewWallet =
        selected2FASettings.contains(VerboseControlSettings.creatingNewWallets);
    final hasSecurityAndBackup =
        selected2FASettings.contains(VerboseControlSettings.securityAndBackupSettings);

    bool isOnlyNarrowPresetControlsPresent = selected2FASettings.length == 4;

    return (hasNonContacts &&
        hasAddContacts &&
        hasCreateNewWallet &&
        hasSecurityAndBackup &&
        isOnlyNarrowPresetControlsPresent);
  }

  @action
  void activateCake2FANormalPreset() {
    _settingsStore.selectedCake2FAPreset = Cake2FAPresetsOptions.normal;
    setAllControlsToFalse();
    switchShouldRequireTOTP2FAForSendsToNonContact(true);
    switchShouldRequireTOTP2FAForSendsToContact(true);
    switchShouldRequireTOTP2FAForSendsToInternalWallets(true);
    switchShouldRequireTOTP2FAForExchangesToInternalWallets(true);
    switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(true);
  }

  @action
  void activateCake2FANarrowPreset() {
    _settingsStore.selectedCake2FAPreset = Cake2FAPresetsOptions.narrow;
    setAllControlsToFalse();
    switchShouldRequireTOTP2FAForSendsToNonContact(true);
    switchShouldRequireTOTP2FAForAddingContacts(true);
    switchShouldRequireTOTP2FAForCreatingNewWallet(true);
    switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(true);
  }

  @action
  void activateCake2FAAggressivePreset() {
    _settingsStore.selectedCake2FAPreset = Cake2FAPresetsOptions.aggressive;
    setAllControlsToFalse();
    switchShouldRequireTOTP2FAForAccessingWallet(true);
    switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(true);
  }

  @action
  void setAllControlsToFalse() {
    switchShouldRequireTOTP2FAForAccessingWallet(false);
    switchShouldRequireTOTP2FAForSendsToContact(false);
    switchShouldRequireTOTP2FAForSendsToNonContact(false);
    switchShouldRequireTOTP2FAForAddingContacts(false);
    switchShouldRequireTOTP2FAForCreatingNewWallet(false);
    switchShouldRequireTOTP2FAForExchangesToInternalWallets(false);
    switchShouldRequireTOTP2FAForSendsToInternalWallets(false);
    switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(false);
    selected2FASettings.clear();
    unhighlightTabs = false;
  }

  @action
  void switchShouldRequireTOTP2FAForAccessingWallet(bool value) {
    _settingsStore.shouldRequireTOTP2FAForAccessingWallet = value;
    if (value) {
      selected2FASettings.add(VerboseControlSettings.accessWallet);
    } else {
      selected2FASettings.remove(VerboseControlSettings.accessWallet);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForSendsToContact(bool value) {
    _settingsStore.shouldRequireTOTP2FAForSendsToContact = value;
    if (value) {
      selected2FASettings.add(VerboseControlSettings.sendsToContacts);
    } else {
      selected2FASettings.remove(VerboseControlSettings.sendsToContacts);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForSendsToNonContact(bool value) {
    _settingsStore.shouldRequireTOTP2FAForSendsToNonContact = value;
    if (value) {
      selected2FASettings.add(VerboseControlSettings.sendsToNonContacts);
    } else {
      selected2FASettings.remove(VerboseControlSettings.sendsToNonContacts);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForSendsToInternalWallets(bool value) {
    _settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets = value;
    if (value) {
      selected2FASettings.add(VerboseControlSettings.sendsToInternalWallets);
    } else {
      selected2FASettings.remove(VerboseControlSettings.sendsToInternalWallets);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForExchangesToInternalWallets(bool value) {
    _settingsStore.shouldRequireTOTP2FAForExchangesToInternalWallets = value;
    if (value) {
      selected2FASettings.add(VerboseControlSettings.exchangesToInternalWallets);
    } else {
      selected2FASettings.remove(VerboseControlSettings.exchangesToInternalWallets);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForAddingContacts(bool value) {
    _settingsStore.shouldRequireTOTP2FAForAddingContacts = value;
    if (value)
      selected2FASettings.add(VerboseControlSettings.addingContacts);
    else {
      selected2FASettings.remove(VerboseControlSettings.addingContacts);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForCreatingNewWallet(bool value) {
    _settingsStore.shouldRequireTOTP2FAForCreatingNewWallets = value;
    if (value) {
      selected2FASettings.add(VerboseControlSettings.creatingNewWallets);
    } else {
      selected2FASettings.remove(VerboseControlSettings.creatingNewWallets);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }

  @action
  void switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(bool value) {
    _settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings = value;
    if (value)
      selected2FASettings.add(VerboseControlSettings.securityAndBackupSettings);
    else {
      selected2FASettings.remove(VerboseControlSettings.securityAndBackupSettings);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }
}
