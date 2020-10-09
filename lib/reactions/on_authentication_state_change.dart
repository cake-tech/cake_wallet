import 'package:cake_wallet/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/router.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';

ReactionDisposer _onAuthenticationStateChange;

void startAuthenticationStateChange(AuthenticationStore authenticationStore,
    @required GlobalKey<NavigatorState> navigatorKey) {
  _onAuthenticationStateChange ??= autorun((_) async {
    final state = authenticationStore.state;

    if (state == AuthenticationState.installed) {
      await loadCurrentWallet();
      return;
    }

    if (state == AuthenticationState.allowed) {
      await navigatorKey.currentState
          .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
      return;
    }

    if (state == AuthenticationState.denied) {
      await navigatorKey.currentState
          .pushNamedAndRemoveUntil(Routes.welcome, (_) => false);
      return;
    }
  });
}
