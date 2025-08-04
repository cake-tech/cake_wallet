import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool requireHardwareWalletConnection() {
  final name = getIt
      .get<SharedPreferences>()
      .getString(PreferencesKey.currentWalletName);
  final typeRaw =
      getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

  if (typeRaw == null) {
    return false;
  }

  if (name == null) {
    throw Exception('Incorrect current wallet name: $name');
  }

  final type = deserializeFromInt(typeRaw);
  final walletLoadingService = getIt.get<WalletLoadingService>();
  return walletLoadingService.requireHardwareWalletConnection(type, name);
}
