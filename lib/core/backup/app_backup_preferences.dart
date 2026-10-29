import "dart:io";
import "dart:isolate";

import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/entities/preferences_key.dart";
import "package:crypto/crypto.dart";
import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

class AppBackupRecord {
  const AppBackupRecord({required this.createdAt, required this.sizeInBytes, this.sha256Hash});

  final DateTime createdAt;
  final int sizeInBytes;
  final String? sha256Hash;

  static Future<AppBackupRecord> forFile(File file) async {
    final path = file.path;
    return AppBackupRecord(
      createdAt: await file.lastModified(),
      sizeInBytes: await file.length(),
      sha256Hash: await Isolate.run(
        () async => (await sha256.bind(File(path).openRead()).first).toString(),
      ),
    );
  }
}

class AppBackupPreferences {
  AppBackupPreferences(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  late final ValueNotifier<bool> homeBannerVisible = ValueNotifier(_isHomeBannerVisible);

  bool get _isHomeBannerVisible =>
      !isSetupCompleted &&
      !(_sharedPreferences.getBool(PreferencesKey.appBackupHomeBannerDismissed) ?? false);

  bool get isSetupCompleted =>
      _sharedPreferences.getBool(PreferencesKey.appBackupSetupCompleted) ?? false;

  Future<void> completeSetup() async {
    await _sharedPreferences.setBool(PreferencesKey.appBackupSetupCompleted, true);
    homeBannerVisible.value = _isHomeBannerVisible;
  }

  Future<void> dismissHomeBanner() async {
    await _sharedPreferences.setBool(PreferencesKey.appBackupHomeBannerDismissed, true);
    homeBannerVisible.value = _isHomeBannerVisible;
  }

  Set<String> get excludedWalletIds =>
      (_sharedPreferences.getStringList(PreferencesKey.appBackupExcludedWalletIds) ?? []).toSet();

  Future<void> setExcludedWalletIds(Set<String> walletIds) => _sharedPreferences.setStringList(
        PreferencesKey.appBackupExcludedWalletIds,
        walletIds.toList(),
      );

  AppBackupStorage? get preferredStorage => AppBackupStorage.fromRaw(
        _sharedPreferences.getString(PreferencesKey.appBackupPreferredStorage),
      );

  Future<void> setPreferredStorage(AppBackupStorage storage) =>
      _sharedPreferences.setString(PreferencesKey.appBackupPreferredStorage, storage.name);

  AppBackupRecord? get lastBackup {
    final timestamp = _sharedPreferences.getInt(PreferencesKey.appBackupLastTimestamp);
    final size = _sharedPreferences.getInt(PreferencesKey.appBackupLastSize);
    return timestamp == null || size == null
        ? null
        : AppBackupRecord(
            createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
            sizeInBytes: size,
            sha256Hash: _sharedPreferences.getString(PreferencesKey.appBackupLastSha256),
          );
  }

  Future<void> recordBackup(AppBackupRecord record) async {
    await _sharedPreferences.setInt(
      PreferencesKey.appBackupLastTimestamp,
      record.createdAt.millisecondsSinceEpoch,
    );
    await _sharedPreferences.setInt(PreferencesKey.appBackupLastSize, record.sizeInBytes);
    final hash = record.sha256Hash;
    hash == null
        ? await _sharedPreferences.remove(PreferencesKey.appBackupLastSha256)
        : await _sharedPreferences.setString(PreferencesKey.appBackupLastSha256, hash);
  }
}
