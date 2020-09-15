import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity/connectivity.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/router.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/services/fiat_convertation_service.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/store/dashboard/fiat_convertation_store.dart';

// FIXME: move me
Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
  final name = getIt.get<SharedPreferences>().getString('current_wallet_name');
  final typeRaw =
      getIt.get<SharedPreferences>().getInt('current_wallet_type') ?? 0;
  final type = deserializeFromInt(typeRaw);
  final password =
      await getIt.get<KeyService>().getWalletPassword(walletName: name);
  final _service = getIt.get<WalletService>(param1: type);
  final wallet = await _service.openWallet(name, password);
  appStore.wallet = wallet;
}

ReactionDisposer _initialAuthReaction;
ReactionDisposer _onCurrentWalletChangeReaction;
ReactionDisposer _onWalletSyncStatusChangeReaction;
ReactionDisposer _onCurrentFiatCurrencyChangeDisposer;
Timer _reconnectionTimer;

Future<void> bootstrap(
    {FiatConvertationService fiatConvertationService,
    GlobalKey<NavigatorState> navigatorKey}) async {
  final authenticationStore = getIt.get<AuthenticationStore>();
  final settingsStore = getIt.get<SettingsStore>();
  final fiatConvertationStore = getIt.get<FiatConvertationStore>();

  if (authenticationStore.state == AuthenticationState.uninitialized) {
    authenticationStore.state =
        getIt.get<SharedPreferences>().getString('current_wallet_name') == null
            ? AuthenticationState.denied
            : AuthenticationState.installed;
  }

  _initialAuthReaction ??= autorun((_) async {
    final state = authenticationStore.state;
    print(state);

    if (state == AuthenticationState.installed) {
      await loadCurrentWallet();
      await navigatorKey.currentState
          .pushAndRemoveUntil(createLoginRoute(), (_) => false);
    }

    if (state == AuthenticationState.allowed) {
      await navigatorKey.currentState
          .pushAndRemoveUntil(createDashboardRoute(), (_) => false);
    }

    if (state == AuthenticationState.denied) {
      await navigatorKey.currentState
          .pushAndRemoveUntil(createWelcomeRoute(), (_) => false);
    }
  });

  _onCurrentWalletChangeReaction ??=
      reaction((_) => getIt.get<AppStore>().wallet, (WalletBase wallet) async {
    _onWalletSyncStatusChangeReaction?.reaction?.dispose();
    _reconnectionTimer?.cancel();
    _onWalletSyncStatusChangeReaction =
        reaction((_) => wallet.syncStatus, (SyncStatus status) async {
      if (status is ConnectedSyncStatus) {
        await wallet.startSync();
      }
    });

    _reconnectionTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      final connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult == ConnectivityResult.none) {
        wallet.syncStatus = FailedSyncStatus();
        return;
      }

      if (wallet.syncStatus is LostConnectionSyncStatus ||
          wallet.syncStatus is FailedSyncStatus) {
        try {
          final alive =
              await settingsStore.getCurrentNode(wallet.type).requestNode();

          if (alive) {
            await wallet.connectToNode(
                node: settingsStore.getCurrentNode(wallet.type));
          }
        } catch (_) {}
      }
    });

    await getIt
        .get<SharedPreferences>()
        .setString('current_wallet_name', wallet.name);

    await getIt
        .get<SharedPreferences>()
        .setInt('current_wallet_type', serializeToInt(wallet.type));

    final node = settingsStore.getCurrentNode(wallet.type);
    final cryptoCurrency = wallet.currency;
    final fiatCurrency = settingsStore.fiatCurrency;

    await wallet.connectToNode(node: node);

    final price = await fiatConvertationService.getPrice(
        crypto: cryptoCurrency, fiat: fiatCurrency);

    fiatConvertationStore.setPrice(price);
  });

  _onCurrentFiatCurrencyChangeDisposer ??= reaction(
      (_) => settingsStore.fiatCurrency, (FiatCurrency fiatCurrency) async {
    final cryptoCurrency = getIt.get<AppStore>().wallet.currency;

    final price = await fiatConvertationService.getPrice(
        crypto: cryptoCurrency, fiat: fiatCurrency);

    fiatConvertationStore.setPrice(price);
  });
}
