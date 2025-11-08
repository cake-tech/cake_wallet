import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LinkViewModel {
  LinkViewModel({
    required this.settingsStore,
    required this.appStore,
    required this.authenticationStore,
    required this.navigatorKey,
  });

  final SettingsStore settingsStore;
  final AppStore appStore;
  final AuthenticationStore authenticationStore;
  final GlobalKey<NavigatorState> navigatorKey;
  Uri? currentLink;

  bool get _isValidPaymentUri => currentLink?.path.isNotEmpty ?? false;
  bool get isWalletConnectLink => currentLink?.authority == 'wc';
  bool get isNanoGptLink => currentLink?.scheme == 'nano-gpt';
  bool get isQuickActionLink =>
      currentLink?.scheme == 'cakewallet' && currentLink?.host == 'quickaction';

  String? getRouteToGo() {
    if (isWalletConnectLink) {
      if (!isEVMCompatibleChain(appStore.wallet!.type)) {
        _errorToast(S.current.switchToEVMCompatibleWallet);
        return null;
      }
      return Routes.walletConnectConnectionsListing;
    }

    // Check for a quick action first.
    if (isQuickActionLink) {
      final action = currentLink!.pathSegments.isNotEmpty ? currentLink!.pathSegments.first : null;
      switch (action) {
        case 'send':
          return Routes.send;
        case 'receive':
          return Routes.receive;
        default:
          return null;
      }
    }

    if (authenticationStore.state == AuthenticationState.uninitialized) {
      return null;
    }

    if (isNanoGptLink) {
      switch (currentLink?.authority ?? '') {
        case "exchange":
          return Routes.exchange;
        case "send":
          return Routes.send;
        case "buy":
          return Routes.buySellPage;
      }
    }

    if (_isValidPaymentUri) {
      return Routes.send;
    }

    return null;
  }

  dynamic getRouteArgs() {
    if (isWalletConnectLink) {
      return currentLink;
    }

    if (isQuickActionLink) {
      return null;
    }

    if (isNanoGptLink) {
      switch (currentLink?.authority ?? '') {
        case "exchange":
          return PaymentRequest.fromUri(currentLink);
        case "send":
          return {"paymentRequest": PaymentRequest.fromUri(currentLink)};
        case "buy":
          return true;
      }
    }

    if (_isValidPaymentUri) {
      return {"paymentRequest": PaymentRequest.fromUri(currentLink)};
    }

    return null;
  }

  Future<void> _errorToast(String message, {double fontSize = 16}) async {
    try {
      await Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: fontSize,
      );
    } catch (_) {}
  }

  Future<void> handleLink() async {
    String? route = getRouteToGo();
    dynamic args = getRouteArgs();
    if (route != null) {
      if (appStore.wallet == null) {
        return;
      }

      // Prevent navigating to the same route again.
      if (appStore.currentRouteName == route) {
        return;
      }

      if (isNanoGptLink) {
        if (route == Routes.buySellPage || route == Routes.exchange) {
          await _errorToast(S.current.nano_gpt_thanks_message, fontSize: 14);
        }
      }
      currentLink = null;
      navigatorKey.currentState?.pushNamed(
        route,
        arguments: args,
      );
    }
  }
}
