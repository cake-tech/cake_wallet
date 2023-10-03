import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;

void startAuthenticationStateChange(AuthenticationStore authenticationStore,
    GlobalKey<NavigatorState> navigatorKey, AppStore appStore) {
  _onAuthenticationStateChange ??= autorun(
    (_) async {
      final state = authenticationStore.state;

      if (state == AuthenticationState.installed) {
        await _loadCurrentWallet();
        return;
      }

      if (state == AuthenticationState.allowed) {
        await _navigateBasedOnWalletType(navigatorKey, appStore);
        return;
      }
    },
  );
}

Future<void> _loadCurrentWallet() async {
  try {
    await loadCurrentWallet();
  } catch (error, stack) {
    loginError = error;
    ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));
  }
}

Future<void> _navigateBasedOnWalletType(
    GlobalKey<NavigatorState> navigatorKey, AppStore appStore) async {
  final wallet = appStore.wallet!;

  if (wallet.type == WalletType.haven) {
    await navigatorKey.currentState!.pushNamedAndRemoveUntil(
      Routes.havenRemovalNoticePage,
      (route) => false,
      arguments: wallet,
    );
    return;
  } else {
    await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
    return;
  }

  // await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
  // return;
}
