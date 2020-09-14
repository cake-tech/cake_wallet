import 'dart:async';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/secret_store_key.dart';
import 'package:cake_wallet/src/domain/common/encrypt.dart';
import 'package:cake_wallet/src/domain/services/fiat_convertation_service.dart';
import 'package:cake_wallet/src/domain/common/fiat_currency.dart';
import 'package:cake_wallet/store/dashboard/fiat_convertation_store.dart';

// FIXME: move me
Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
  //final name = 'test';
  final name = getIt.get<SharedPreferences>().getString('current_wallet_name');
  final typeRaw =
      getIt.get<SharedPreferences>().getInt('current_wallet_type') ?? 0;
  final type = deserializeFromInt(typeRaw);
  final password =
      await getIt.get<KeyService>().getWalletPassword(walletName: name);

  WalletService _service;
  switch (type) {
    case WalletType.monero:
      _service = MoneroWalletService();
      break;
    case WalletType.bitcoin:
      _service = BitcoinWalletService();
      break;
    default:
      break;
  }

  final wallet = await _service.openWallet(name, password);
  appStore.wallet = wallet;
}

ReactionDisposer _initialAuthReaction;
ReactionDisposer _onCurrentWalletChangeReaction;
ReactionDisposer _onWalletSyncStatusChangeReaction;
ReactionDisposer _onCurrentFiatCurrencyChangeDisposer;
Timer _reconnectionTimer;

Future<void> bootstrap(
    {FiatConvertationService fiatConvertationService}) async {
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

    if (state == AuthenticationState.installed) {
      await loadCurrentWallet();
    }
  });

  _onCurrentWalletChangeReaction ??=
      reaction((_) => getIt.get<AppStore>().wallet, (WalletBase wallet) async {
    _onWalletSyncStatusChangeReaction?.reaction?.dispose();
    _reconnectionTimer?.cancel();
    _onWalletSyncStatusChangeReaction = reaction(
        (_) => wallet.syncStatus is ConnectedSyncStatus,
        (Object _) async => await wallet.startSync());

    _reconnectionTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (wallet.syncStatus is LostConnectionSyncStatus ||
          wallet.syncStatus is FailedSyncStatus) {
        try {
          await wallet.connectToNode(
              node: settingsStore.getCurrentNode(wallet.type));
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
