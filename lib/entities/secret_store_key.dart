import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SecretStoreKey { moneroWalletPassword, pinCodePassword, backupPassword }

const moneroWalletPassword = "MONERO_WALLET_PASSWORD";
const pinCodePassword = "PIN_CODE_PASSWORD";
const backupPassword = "BACKUP_CODE_PASSWORD";

String generateStoreKeyFor({
  required SecretStoreKey key,
  String walletName = "",
}) {
  var _key = "";

  switch (key) {
    case SecretStoreKey.moneroWalletPassword:
      {
        _key = moneroWalletPassword + "_" + walletName.toUpperCase();
      }
      break;

    case SecretStoreKey.pinCodePassword:
      {
        _key = pinCodePassword;
      }
      break;

    case SecretStoreKey.backupPassword:
      {
        _key = backupPassword;
      }
      break;

    default:
      {}
  }

  return _key;
}

class SecureKey {
  static const allowBiometricalAuthenticationKey = 'allow_biometrical_authentication';
  static const useTOTP2FA = 'use_totp_2fa';
  static const shouldRequireTOTP2FAForAccessingWallet =
      'should_require_totp_2fa_for_accessing_wallets';
  static const shouldRequireTOTP2FAForSendsToContact =
      'should_require_totp_2fa_for_sends_to_contact';
  static const shouldRequireTOTP2FAForSendsToNonContact =
      'should_require_totp_2fa_for_sends_to_non_contact';
  static const shouldRequireTOTP2FAForSendsToInternalWallets =
      'should_require_totp_2fa_for_sends_to_internal_wallets';
  static const shouldRequireTOTP2FAForExchangesToInternalWallets =
      'should_require_totp_2fa_for_exchanges_to_internal_wallets';
  static const shouldRequireTOTP2FAForExchangesToExternalWallets =
      'should_require_totp_2fa_for_exchanges_to_external_wallets';
  static const shouldRequireTOTP2FAForAddingContacts =
      'should_require_totp_2fa_for_adding_contacts';
  static const shouldRequireTOTP2FAForCreatingNewWallets =
      'should_require_totp_2fa_for_creating_new_wallets';
  static const shouldRequireTOTP2FAForAllSecurityAndBackupSettings =
      'should_require_totp_2fa_for_all_security_and_backup_settings';
  static const selectedCake2FAPreset = 'selected_cake_2fa_preset';
  static const totpSecretKey = 'totp_secret_key';
  static const pinTimeOutDuration = 'pin_timeout_duration';
  static const lastAuthTimeMilliseconds = 'last_auth_time_milliseconds';

  static Future<int?> getInt({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences sharedPreferences,
    required String key,
  }) async {
    int? value = int.tryParse((await secureStorage.read(key: key) ?? ''));
    value ??= sharedPreferences.getInt(key);
    return value;
  }

  static Future<bool?> getBool({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences sharedPreferences,
    required String key,
  }) async {
    String? value = (await secureStorage.read(key: key) ?? '');
    if (value.toLowerCase() == "true") {
      return true;
    } else if (value.toLowerCase() == "false") {
      return false;
    } else {
      return sharedPreferences.getBool(key);
    }
  }

  static Future<String?> getString({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences sharedPreferences,
    required String key,
  }) async {
    String? value = await secureStorage.read(key: key);
    value ??= sharedPreferences.getString(key);
    return value;
  }
}
