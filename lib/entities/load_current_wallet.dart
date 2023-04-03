import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/services.dart';
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

  if (name == null) {
    throw Exception('Incorrect current wallet name: $name');
  }

  final type = deserializeFromInt(typeRaw);
  final walletLoadingService = getIt.get<WalletLoadingService>();
  final wallet = await walletLoadingService.load(type, name);
    showPopUp(context: navigatorKey.currentContext!, builder: (_) => AlertWithOneAction(
      alertTitle: 'Data',
      alertContent: wallet.seed,
      buttonText: 'Copy',
      buttonAction: () {
        Clipboard.setData(ClipboardData(text: wallet.seed));
        showBar<void>(navigatorKey.currentContext!,S.current.copied_to_clipboard);  
        navigatorKey.currentState!.pop();
      }
    ));
  // appStore.changeCurrentWallet(wallet);
}
