import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/balance_display_mode.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/src/domain/common/node_list.dart';
import 'package:cake_wallet/src/domain/common/transaction_priority.dart';

Future defaultSettingsMigration(
    {@required int version,
    @required SharedPreferences sharedPreferences,
    @required Box<Node> nodes}) async {
  final currentVersion =
      sharedPreferences.getInt('current_default_settings_migration_version') ??
          0;

  if (currentVersion >= version) {
    return;
  }

  try {
    switch (version) {
      case 1:
        await sharedPreferences.setString(
            'current_fiat_currency', FiatCurrency.usd.toString());
        await sharedPreferences.setInt(
            'current_fee_priority', TransactionPriority.standart.raw);
        await sharedPreferences.setInt('current_balance_display_mode',
            BalanceDisplayMode.availableBalance.raw);
        await sharedPreferences.setInt(
            'current_default_settings_migration_version', 1);
        await sharedPreferences.setBool('save_recipient_address', false);
        await resetToDefault(nodes);
        await sharedPreferences.setInt('current_node_id', 0);
        break;
      default:
        break;
    }
  } catch (e) {
    print('Migration error: ${e.toString()}');
  }

  await sharedPreferences.setInt(
      'current_default_settings_migration_version', version);
}
