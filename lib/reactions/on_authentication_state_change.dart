import 'dart:async';

import 'package:cake_wallet/entities/hardware_wallet/require_hardware_wallet_connection.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/connect_device/connect_device_page.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/wallet_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/load_current_wallet.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:rxdart/subjects.dart';

ReactionDisposer? _onAuthenticationStateChange;

dynamic loginError;
StreamController<dynamic> authenticatedErrorStreamController =
    BehaviorSubject<dynamic>();

void startAuthenticationStateChange(
  AuthenticationStore authenticationStore,
  GlobalKey<NavigatorState> navigatorKey,
) {
  authenticatedErrorStreamController.stream.listen((event) {
    if (authenticationStore.state == AuthenticationState.allowed) {
      ExceptionHandler.showError(event.toString(), delayInSeconds: 3);
    }
  });

  _onAuthenticationStateChange ??= autorun((_) async {
    final state = authenticationStore.state;

    if (state == AuthenticationState.installed &&
        !SettingsStoreBase.walletPasswordDirectInput) {
      try {
        if (!requireHardwareWalletConnection()) await loadCurrentWallet();
      } catch (error, stack) {
        loginError = error;
        ExceptionHandler.onError(
            FlutterErrorDetails(exception: error, stack: stack));
      }
      return;
    }

    if (state == AuthenticationState.allowed) {
      if (requireHardwareWalletConnection()) {
        await navigatorKey.currentState!.pushNamedAndRemoveUntil(
            Routes.connectDevices, (route) => false,
            arguments: ConnectDevicePageParams(
                walletType: WalletType.monero,
                onConnectDevice: (context, ledgerVM) async {
                  gLedger = ledgerVM.connection;
                  await loadCurrentWallet();
                  await navigatorKey.currentState!
                      .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
                }, allowChangeWallet: true));

        // await navigatorKey.currentState!.pushNamedAndRemoveUntil(Routes.connectDevices, (route) => false, arguments: ConnectDevicePageParams(walletType: walletType, onConnectDevice: onConnectDevice));
      } else {
        await navigatorKey.currentState!
            .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false);
      }
      if (!(await authenticatedErrorStreamController.stream.isEmpty)) {
        ExceptionHandler.showError(
            (await authenticatedErrorStreamController.stream.first).toString());
        authenticatedErrorStreamController.stream.drain();
      }
      return;
    }
  });
}
