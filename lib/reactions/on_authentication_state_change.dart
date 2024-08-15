import 'dart:async';

import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:rxdart/subjects.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;
StreamController<dynamic> authenticatedErrorStreamController = BehaviorSubject();

void startAuthenticationStateChange(
    AuthenticationStore authenticationStore, GlobalKey<NavigatorState> navigatorKey) {
  authenticatedErrorStreamController.stream.listen((event) {
    if (authenticationStore.state == AuthenticationState.allowed) {
      ExceptionHandler.showError(event.toString(), delayInSeconds: 3);
    }
  });

  _onAuthenticationStateChange ??= autorun((_) async {
    final state = authenticationStore.state;

    if (state == AuthenticationState.installed && !SettingsStoreBase.walletPasswordDirectInput) {
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
      if (!(await authenticatedErrorStreamController.stream.isEmpty)) {
        ExceptionHandler.showError(
          (await authenticatedErrorStreamController.stream.first).toString(),
        );
        authenticatedErrorStreamController.stream.drain();
      }
      return;
    }
  });
}
