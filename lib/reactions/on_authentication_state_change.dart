import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;

void startAuthenticationStateChange(AuthenticationStore authenticationStore,
    GlobalKey<NavigatorState> navigatorKey) {
  _onAuthenticationStateChange ??= autorun((_) async {

      try {
        await loadCurrentWallet();
      } catch (error, stack) {
        loginError = error;
        ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));
      }
      return;
    }

 );
}
