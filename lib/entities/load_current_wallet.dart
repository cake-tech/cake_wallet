import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import "package:cake_wallet/new-ui/services/wallet_pool_service.dart";
import "package:cw_core/wallet_info.dart";

Future<void> loadCurrentWallet({String? password}) async {
  final name = getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);
  final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType) ?? 0;

  if (name == null) {
    throw Exception('Incorrect current wallet name: $name');
  }

  final type = deserializeFromInt(typeRaw);
  final walletLoadingService = getIt.get<WalletLoadingService>();
  final walletPoolService = getIt.get<WalletPoolService>();

  try {
    await walletPoolService.switchTo(WalletKey(name, type),
        load: () => walletLoadingService.open(type, name, password: password));
  } catch (error, stack) {
    final wallet = await walletLoadingService.recover(type, name, error, stack);
    await walletPoolService.switchTo(wallet.key, load: () async => wallet);
  }
}
