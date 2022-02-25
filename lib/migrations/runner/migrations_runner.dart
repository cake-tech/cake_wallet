import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/fs_migration.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/migrations/runner/switch.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';

Future<void> runDefaultMigrations(
    {@required int version,
    @required Box<WalletInfo> walletInfoSource,
    @required Box<Trade> tradeSource,
    @required Box<Contact> contactSource}) async {
  if (Platform.isIOS) {
    await ios_migrate_v1(walletInfoSource, tradeSource, contactSource);
  }
  final sharedPreferences = getIt.get<SharedPreferences>();

  final currentVersion = sharedPreferences
          .getInt(PreferencesKey.currentDefaultSettingsMigrationVersion) ??
      0;
  if (currentVersion >= version) {
    return;
  }

  final migrationVersionsLength = version - currentVersion;
  final migrationVersions = List<int>.generate(
      migrationVersionsLength, (i) => currentVersion + (i + 1));

  await Future.forEach(migrationVersions, (int version) async {
    try {
      await switchMigrations(version);
      await sharedPreferences.setInt(
          'current_default_settings_migration_version', version);
    } catch (e) {
      print('Migration error: ${e.toString()}');
    }
  });

  await sharedPreferences.setInt(
      'current_default_settings_migration_version', version);
}
