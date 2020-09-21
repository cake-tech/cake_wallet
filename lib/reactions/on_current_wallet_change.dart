import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/reactions/check_connection.dart';
import 'package:cake_wallet/reactions/on_wallet_sync_status_change.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

ReactionDisposer _onCurrentWalletChangeReaction;

void startCurrentWalletChangeReaction(AppStore appStore,
    SettingsStore settingsStore, FiatConversionStore fiatConversionStore) {
  _onCurrentWalletChangeReaction?.reaction?.dispose();

  _onCurrentWalletChangeReaction =
      reaction((_) => appStore.wallet, (WalletBase wallet) async {
    try {
      final node = settingsStore.getCurrentNode(wallet.type);
      startWalletSyncStatusChangeReaction(wallet);
      startCheckConnectionReaction(wallet, settingsStore);
      await getIt
          .get<SharedPreferences>()
          .setString(PreferencesKey.currentWalletName, wallet.name);
      await getIt.get<SharedPreferences>().setInt(
          PreferencesKey.currentWalletType, serializeToInt(wallet.type));
      await wallet.connectToNode(node: node);

      fiatConversionStore.price = await FiatConversionService.fetchPrice(
          wallet.currency, settingsStore.fiatCurrency);
    } catch (e) {
      print(e.toString());
    }
  });
}
