import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/wallet_type.dart';

Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
  final name = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName);
  final typeRaw =
      getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType) ??
          0;
  final type = deserializeFromInt(typeRaw);
  final password =
      await getIt.get<KeyService>().getWalletPassword(walletName: name);
  final _service = getIt.get<WalletService>(param1: type);
  final wallet = await _service.openWallet(name, password);
  appStore.wallet = wallet;
}
