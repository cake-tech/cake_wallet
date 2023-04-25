import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;

void startAuthenticationStateChange(
    AuthenticationStore authenticationStore, GlobalKey<NavigatorState> navigatorKey) {
  _onAuthenticationStateChange ??= autorun((_) async {
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
      await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
      return;
    }
  });
}
