import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;

void startAuthenticationStateChange(
    AuthenticationStore authenticationStore, GlobalKey<NavigatorState> navigatorKey) {
  _onAuthenticationStateChange ??= autorun(
    (_) async {
      final state = authenticationStore.state;

      if (state == AuthenticationState.installed) {
        try {
          await loadCurrentWallet();
        } catch (error, stack) {
          loginError = error;
          ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));
        }
        return;
      }

      if (state == AuthenticationState.allowed) {
        final typeRaw =
            getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType) ?? 0;

        final type = deserializeFromInt(typeRaw);

        if (type == WalletType.haven) {
          await navigatorKey.currentState!
              .pushNamedAndRemoveUntil(Routes.preSeed, (route) => false, arguments: type);
          await navigatorKey.currentState!.pushNamed(Routes.seed, arguments: true);
          await navigatorKey.currentState!
              .pushNamedAndRemoveUntil(Routes.welcome, (route) => false);
          return;
        } else {
          await navigatorKey.currentState!
              .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
          return;
        }
      }
    },
  );
}
