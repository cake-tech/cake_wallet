import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MigrationV10 {
  static Future<void> run() async {
    final sharedPreferences = getIt.get<SharedPreferences>();
    await changeTransactionPriorityAndFeeRateKeys(sharedPreferences);
  }

  static Future<void> changeTransactionPriorityAndFeeRateKeys(
      SharedPreferences sharedPreferences) async {
    final legacyTransactionPriority = sharedPreferences
        .getInt(PreferencesKey.currentTransactionPriorityKeyLegacy);
    await sharedPreferences.setInt(
        PreferencesKey.moneroTransactionPriority, legacyTransactionPriority);
    await sharedPreferences.setInt(PreferencesKey.bitcoinTransactionPriority,
        bitcoin.getMediumTransactionPriority().serialize());
  }
}
