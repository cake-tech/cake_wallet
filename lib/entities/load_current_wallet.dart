import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';

Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
  final name = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName);
  final typeRaw =
      getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType) ??
          0;
  final type = deserializeFromInt(typeRaw);
  final walletLoadingService = getIt.get<WalletLoadingService>();
  final wallet = await walletLoadingService.load(type, name);
  appStore.changeCurrentWallet(wallet);
}
