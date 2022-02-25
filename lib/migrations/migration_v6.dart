import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationV6 {
  static Future<void> run() async {
    final sharedPreferences = getIt.get<SharedPreferences>();
    await updateDisplayModes(sharedPreferences);
  }

  static Future<void> updateDisplayModes(
      SharedPreferences sharedPreferences) async {
    final currentBalanceDisplayMode =
        sharedPreferences.getInt(PreferencesKey.currentBalanceDisplayModeKey);
    final balanceDisplayMode = currentBalanceDisplayMode < 2 ? 3 : 2;
    await sharedPreferences.setInt(
        PreferencesKey.currentBalanceDisplayModeKey, balanceDisplayMode);
  }
}
