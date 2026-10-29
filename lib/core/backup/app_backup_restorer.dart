import "dart:io";

import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/secret_store_key.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/authentication_store.dart";
import "package:mobx/mobx.dart";

class AppBackupWrongPasswordException implements Exception {
  const AppBackupWrongPasswordException();
}

class AppBackupRestorer {
  AppBackupRestorer(this._backupService, this._secureStorage);

  final BackupServiceV3 _backupService;
  final SecureStorage _secureStorage;

  Future<bool> hasPin() async =>
      (await _secureStorage.read(key: generateStoreKeyFor(key: SecretStoreKey.pinCodePassword)))
          ?.isNotEmpty ??
      false;

  bool isBackupFile(File file) {
    try {
      return _backupService.getVersionFile(file) != BackupVersion.unknown;
    } catch (_) {
      return false;
    }
  }

  Future<void> restore(File file, String password, {bool checkBackupApp = true}) async {
    try {
      await _backupService.importBackupFile(file, password, checkBackupApp: checkBackupApp);
    } on IncompatibleBackupAppException {
      rethrow;
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains("message authentication code (mac)") ||
          message.contains("faileddecryption")) {
        throw const AppBackupWrongPasswordException();
      }
      rethrow;
    }

    await initializeAppAtRoot(reInitializing: true);
    final store = getIt.get<AppStore>();
    await store.settingsStore.reload();
    await store.themeStore.loadSavedTheme(isFromBackup: true);
    when(
      (_) => store.wallet != null,
      () => store.authenticationStore.state = AuthenticationState.allowed,
    );
  }
}
