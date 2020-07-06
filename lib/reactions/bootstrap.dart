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
import 'package:cake_wallet/store/authentication_store.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/secret_store_key.dart';
import 'package:cake_wallet/src/domain/common/encrypt.dart';

// FIXME: move me
Future<void> loadCurrentWallet() async {
  final appStore = getIt.get<AppStore>();
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

  _onCurrentWalletChangeReaction ??=
      reaction((_) => getIt.get<AppStore>().wallet, (WalletBase wallet) async {
    print('Wallet name ${wallet.name}');

    _onWalletSyncStatusChangeReaction?.reaction?.dispose();
    _onWalletSyncStatusChangeReaction = when(
        (_) => wallet.syncStatus is ConnectedSyncStatus,
        () async => await wallet.startSync());

    await getIt
        .get<SharedPreferences>()
        .setString('current_wallet_name', wallet.name);

    await getIt
        .get<SharedPreferences>()
        .setInt('current_wallet_type', serializeToInt(wallet.type));

    await wallet.connectToNode(node: null);
  });
}
