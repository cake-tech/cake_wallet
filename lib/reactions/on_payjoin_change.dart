import 'package:cake_wallet/entities/payjoin/payjoin_server.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

void startPayjoinConfigReaction(
  AppStore appStore,
  SettingsStore settingsStore,
  SharedPreferences sharedPreferences,
) {
  reaction<bool>((_) => settingsStore.usePayjoin, (bool usePayjoin) {
    final wallet = appStore.wallet;
    if (!usePayjoin || wallet == null) return;
    PayjoinServer.applyMailroomConfig(wallet, sharedPreferences);
  });
}
