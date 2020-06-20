import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/secret_store_key.dart';
import 'package:cake_wallet/src/domain/common/encrypt.dart';

// FIXME: move me
Future<String> getWalletPassword({String walletName}) async {
  final secureStorage = getIt.get<FlutterSecureStorage>();
  final key = generateStoreKeyFor(
      key: SecretStoreKey.moneroWalletPassword, walletName: walletName);
  final encodedPassword = await secureStorage.read(key: key);

  return decodeWalletPassword(password: encodedPassword);
}

// FIXME: move me
Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
  final name = getIt.get<SharedPreferences>().getString('current_wallet_name');
  final type = WalletType.monero; // FIXME
  final password = await getWalletPassword(walletName: name);

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

Future<void> bootstrap() async {
  final authenticationStore = getIt.get<AuthenticationStore>();

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
}
