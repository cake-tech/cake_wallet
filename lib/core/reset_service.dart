import 'package:cake_wallet/core/secure_storage.dart';
import 'package:cake_wallet/entities/secret_store_key.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cw_core/utils/print_verbose.dart';

class ResetService {
  ResetService({
    required this.secureStorage,
    required this.authenticationStore,
    required this.settingsStore,
  });

  final SecureStorage secureStorage;
  final AuthenticationStore authenticationStore;
  final SettingsStore settingsStore;

  static const List<String> _authKeys = [
    SecureKey.allowBiometricalAuthenticationKey,
    SecureKey.useTOTP2FA,
    SecureKey.shouldRequireTOTP2FAForAccessingWallet,
    SecureKey.shouldRequireTOTP2FAForSendsToContact,
    SecureKey.shouldRequireTOTP2FAForSendsToNonContact,
    SecureKey.shouldRequireTOTP2FAForSendsToInternalWallets,
    SecureKey.shouldRequireTOTP2FAForExchangesToInternalWallets,
    SecureKey.shouldRequireTOTP2FAForExchangesToExternalWallets,
    SecureKey.shouldRequireTOTP2FAForAddingContacts,
    SecureKey.shouldRequireTOTP2FAForCreatingNewWallets,
    SecureKey.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
    SecureKey.selectedCake2FAPreset,
    SecureKey.totpSecretKey,
    SecureKey.pinTimeOutDuration,
    SecureKey.lastAuthTimeMilliseconds,
    'PIN_CODE_PASSWORD',
  ];

  bool _isAuthKey(String key) => _authKeys.contains(key);

  /// Checks if this is a new install and clears any existing auth data from Keychain
  Future<void> resetAuthDataOnNewInstall(SharedPreferences sharedPreferences) async {
    try {
      final isNewInstall = sharedPreferences.getBool(PreferencesKey.isNewInstall) ?? false;

      if (isNewInstall) {
        await _clearExistingAuthDataOnNewInstall();
      }
    } catch (e) {
      printV('Error during new install auth reset: $e');
    }
  }

  /// Checks if there's existing auth data that should be cleared on new install
  Future<void> _clearExistingAuthDataOnNewInstall() async {
    final allKeys = await secureStorage.readAll();
    final authKeysFound = <String>[];

    for (final key in allKeys.keys) {
      if (_isAuthKey(key)) {
        authKeysFound.add(key);
      }
    }

    if (authKeysFound.isNotEmpty) {
      printV(
        'Found ${authKeysFound.length} existing auth keys in storage: ${authKeysFound.join(', ')}',
      );

      await resetAuthenticationData();
    }
  }

  /// Resets authentication data from both secure storage and settings store
  Future<void> resetAuthenticationData() async {
    try {
      await Future.wait([
        _deleteAuthenticationKeys(),
        _resetSettingsStoreAuthData(),
      ]);
    } catch (e) {
      printV('An error occurred during authentication reset: $e');
      rethrow;
    }
  }

  /// Resets authentication-related data in SettingsStore to default values
  Future<void> _resetSettingsStoreAuthData() async {
    settingsStore.useTOTP2FA = false;
    settingsStore.totpSecretKey = '';
    settingsStore.shouldRequireTOTP2FAForAccessingWallet = false;
    settingsStore.shouldRequireTOTP2FAForSendsToContact = false;
    settingsStore.shouldRequireTOTP2FAForSendsToNonContact = false;
    settingsStore.shouldRequireTOTP2FAForSendsToInternalWallets = false;
    settingsStore.shouldRequireTOTP2FAForExchangesToInternalWallets = false;
    settingsStore.shouldRequireTOTP2FAForExchangesToExternalWallets = false;
    settingsStore.shouldRequireTOTP2FAForAddingContacts = false;
    settingsStore.shouldRequireTOTP2FAForCreatingNewWallets = false;
    settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings = false;
    settingsStore.allowBiometricalAuthentication = false;
  }

  /// Deletes authentication keys from secure storage
  Future<void> _deleteAuthenticationKeys() async {
    final failedDeletions = <String>[];

    final deletionFutures = _authKeys.map((key) async {
      try {
        await secureStorage.delete(key: key);
      } catch (e) {
        failedDeletions.add(key);
      }
    });

    await Future.wait(deletionFutures);

    if (failedDeletions.isNotEmpty) {
      printV(
        'Warning: Failed to delete ${failedDeletions.length} auth keys: ${failedDeletions.join(', ')}',
      );
    } else {
      printV('All auth keys deleted successfully');
    }
  }
}
