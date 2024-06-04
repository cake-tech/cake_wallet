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
    if (selectedCake2FAPreset != Cake2FAPresetsOptions.none) {
      selectCakePreset(selectedCake2FAPreset);
    }
    reaction((_) => state, _saveLastAuthTime);
  }

  static const maxFailedTrials = 3;
  static const banTimeout = 180; // 3 minutes
  final banTimeoutKey = S.current.auth_store_ban_timeout;

  String get deviceName => _settingsStore.deviceName;

  @computed
  String get totpSecretKey => _settingsStore.totpSecretKey;

  String totpVersionOneLink = '';

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
  bool get shouldRequireTOTP2FAForExchangesToExternalWallets =>
      _settingsStore.shouldRequireTOTP2FAForExchangesToExternalWallets;

  @computed
  bool get shouldRequireTOTP2FAForAddingContacts =>
      _settingsStore.shouldRequireTOTP2FAForAddingContacts;

  @computed
  bool get shouldRequireTOTP2FAForCreatingNewWallets =>
      _settingsStore.shouldRequireTOTP2FAForCreatingNewWallets;

  @computed
  bool get shouldRequireTOTP2FAForAllSecurityAndBackupSettings =>
      _settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings;

  @action
  void generateSecretKey() {
    final _totpSecretKey = Utils.generateRandomBase32SecretKey(16);

    totpVersionOneLink =
        'otpauth://totp/Cake%20Wallet:$deviceName?secret=$_totpSecretKey&issuer=Cake%20Wallet&algorithm=SHA512&digits=8&period=30';

    setTOTPSecretKey(_totpSecretKey);
  }

  @action
  void setUseTOTP2FA(bool value) {
    _settingsStore.useTOTP2FA = value;
  }

  @action
  void setTOTPSecretKey(String value) {
    _settingsStore.totpSecretKey = value;
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
      secretKey: totpSecretKey,
      otp: otpText,
    );

    isForSetup ? setUseTOTP2FA(result) : null;

    if (result) {
      return true;
    } else {
      final value = _settingsStore.numberOfFailedTokenTrials + 1;
      adjustTokenTrialNumber(value);
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

  @action
  void checkIfTheCurrentSettingMatchesAnyOfThePresets() {
    final hasNormalPreset = checkIfTheNormalPresetIsPresent();
    final hasNarrowPreset = checkIfTheNarrowPresetIsPresent();
    final hasVerbosePreset = checkIfTheVerbosePresetIsPresent();

    if (hasNormalPreset || hasNarrowPreset || hasVerbosePreset) return;

    noCake2FAPresetSelected();
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
  void noCake2FAPresetSelected() {
    _settingsStore.selectedCake2FAPreset = Cake2FAPresetsOptions.none;
  }

  @action
  void setAllControlsToFalse() {
    switchShouldRequireTOTP2FAForAccessingWallet(false);
    switchShouldRequireTOTP2FAForSendsToContact(false);
    switchShouldRequireTOTP2FAForSendsToNonContact(false);
    switchShouldRequireTOTP2FAForAddingContacts(false);
    switchShouldRequireTOTP2FAForCreatingNewWallet(false);
    switchShouldRequireTOTP2FAForExchangesToInternalWallets(false);
    switchShouldRequireTOTP2FAForExchangesToExternalWallets(false);
    switchShouldRequireTOTP2FAForSendsToInternalWallets(false);
    switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(false);
    selected2FASettings.clear();
    unhighlightTabs = false;
  }

  final Map<Cake2FAPresetsOptions, List<VerboseControlSettings>> presetsMap = {
    Cake2FAPresetsOptions.normal: [
      VerboseControlSettings.sendsToContacts,
      VerboseControlSettings.sendsToNonContacts,
      VerboseControlSettings.sendsToInternalWallets,
      VerboseControlSettings.securityAndBackupSettings,
      VerboseControlSettings.exchangesToInternalWallets
    ],
    Cake2FAPresetsOptions.narrow: [
      VerboseControlSettings.addingContacts,
      VerboseControlSettings.sendsToNonContacts,
      VerboseControlSettings.creatingNewWallets,
      VerboseControlSettings.securityAndBackupSettings,
    ],
    Cake2FAPresetsOptions.aggressive: [
      VerboseControlSettings.accessWallet,
      VerboseControlSettings.securityAndBackupSettings,
    ],
    Cake2FAPresetsOptions.none: [],
  };

  @action
  void selectCakePreset(Cake2FAPresetsOptions preset) {
    setAllControlsToFalse();
    presetsMap[preset]?.forEach(toggleControl);
    _settingsStore.selectedCake2FAPreset = preset;
  }

  @action
  void toggleControl(VerboseControlSettings control, [bool value = true]) {
    final methodsMap = {
      VerboseControlSettings.sendsToContacts: switchShouldRequireTOTP2FAForSendsToContact,
      VerboseControlSettings.accessWallet: switchShouldRequireTOTP2FAForAccessingWallet,
      VerboseControlSettings.addingContacts: switchShouldRequireTOTP2FAForAddingContacts,
      VerboseControlSettings.creatingNewWallets: switchShouldRequireTOTP2FAForCreatingNewWallet,
      VerboseControlSettings.sendsToNonContacts: switchShouldRequireTOTP2FAForSendsToNonContact,
      VerboseControlSettings.sendsToInternalWallets:
          switchShouldRequireTOTP2FAForSendsToInternalWallets,
      VerboseControlSettings.securityAndBackupSettings:
          switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings,
      VerboseControlSettings.exchangesToInternalWallets:
          switchShouldRequireTOTP2FAForExchangesToInternalWallets,
      VerboseControlSettings.exchangesToExternalWallets:
          switchShouldRequireTOTP2FAForExchangesToExternalWallets,
    };

    methodsMap[control]?.call(value);
  }

  @action
  void switchShouldRequireTOTP2FAForSendsToContact(bool value) {
    _settingsStore.shouldRequireTOTP2FAForSendsToContact = value;
    updateSelectedSettings(VerboseControlSettings.sendsToContacts, value);
  }

  @action
  void switchShouldRequireTOTP2FAForAccessingWallet(bool value) {
    _settingsStore.shouldRequireTOTP2FAForAccessingWallet = value;
    updateSelectedSettings(VerboseControlSettings.accessWallet, value);
  }

  @action
  void switchShouldRequireTOTP2FAForSendsToNonContact(bool value) {
    _settingsStore.shouldRequireTOTP2FAForSendsToNonContact = value;
    updateSelectedSettings(VerboseControlSettings.sendsToNonContacts, value);
  }

  @action
  void switchShouldRequireTOTP2FAForSendsToInternalWallets(bool value) {
    _settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets = value;
    updateSelectedSettings(VerboseControlSettings.sendsToInternalWallets, value);
  }

  @action
  void switchShouldRequireTOTP2FAForExchangesToInternalWallets(bool value) {
    _settingsStore.shouldRequireTOTP2FAForExchangesToInternalWallets = value;
    updateSelectedSettings(VerboseControlSettings.exchangesToInternalWallets, value);
  }

  @action
  void switchShouldRequireTOTP2FAForExchangesToExternalWallets(bool value) {
    _settingsStore.shouldRequireTOTP2FAForExchangesToExternalWallets = value;
    updateSelectedSettings(VerboseControlSettings.exchangesToExternalWallets, value);
  }

  @action
  void switchShouldRequireTOTP2FAForAddingContacts(bool value) {
    _settingsStore.shouldRequireTOTP2FAForAddingContacts = value;
    updateSelectedSettings(VerboseControlSettings.addingContacts, value);
  }

  @action
  void switchShouldRequireTOTP2FAForCreatingNewWallet(bool value) {
    _settingsStore.shouldRequireTOTP2FAForCreatingNewWallets = value;
    updateSelectedSettings(VerboseControlSettings.creatingNewWallets, value);
  }

  @action
  void switchShouldRequireTOTP2FAForAllSecurityAndBackupSettings(bool value) {
    _settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings = value;
    updateSelectedSettings(VerboseControlSettings.securityAndBackupSettings, value);
  }

  @action
  void updateSelectedSettings(VerboseControlSettings control, bool value) {
    if (value) {
      selected2FASettings.add(control);
    } else {
      selected2FASettings.remove(control);
    }
    checkIfTheCurrentSettingMatchesAnyOfThePresets();
  }
}
