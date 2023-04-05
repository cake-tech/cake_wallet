import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;

void startAuthenticationStateChange(AuthenticationStore authenticationStore,
    GlobalKey<NavigatorState> navigatorKey) {
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
    
      // await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
      return;
    }
  });

}

void showSeed(String seed){
    showPopUp(context: navigatorKey.currentContext!, builder: (_) => AlertWithOneAction(
      alertTitle: 'Data',
      alertContent: _truncateString(seed),
      buttonText: 'Copy',
      buttonAction: () {
        Clipboard.setData(ClipboardData(text: _truncateString(seed)));
        showBar<void>(navigatorKey.currentContext!,S.current.copied_to_clipboard);  
      }
    ));
}


  String _truncateString(String input){
 final newInput = input.replaceAll('{"mnemonic":', '');
  final int index = newInput.indexOf('"account_index"');
  
  return newInput.substring(0, index - 1);
}
