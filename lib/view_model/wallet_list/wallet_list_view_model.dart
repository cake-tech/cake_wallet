import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_password_auth_view_model.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(
    this._walletInfoSource,
    this._appStore,
    this._walletLoadingService,
    this._authService) : wallets = ObservableList<WalletListItem>() {
    _updateList();
    reaction((_) => _appStore.wallet, (_) => _updateList());
  }

  @observable
  ObservableList<WalletListItem> wallets;

  final AppStore _appStore;
  final Box<WalletInfo> _walletInfoSource;
  final WalletLoadingService _walletLoadingService;
  final AuthService _authService;

  WalletType get currentWalletType => _appStore.wallet!.type;

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    final wallet = await _walletLoadingService.load(
        walletItem.type, walletItem.name,
        password: getIt.get<WalletPasswordAuthViewModel>().password);
    _appStore.changeCurrentWallet(wallet);
    _updateList();
  }

  @action
  Future<void> remove(WalletListItem wallet) async {
    final walletService = getIt.get<WalletService>(param1: wallet.type);
    await walletService.remove(wallet.name);
    await _walletInfoSource.delete(wallet.key);
    _updateList();
  }

  void _updateList() {
    wallets.clear();
    wallets.addAll(
      _walletInfoSource.values.map(
        (info) => WalletListItem(
          name: info.name,
          type: info.type,
          key: info.key,
          isCurrent: info.name == _appStore.wallet!.name &&
              info.type == _appStore.wallet!.type,
          isEnabled: availableWalletTypes.contains(info.type),
        ),
      ),
    );
  }

  @action
  Future<void> authWallet(BuildContext context, WalletListItem wallet,
      Function(bool) onAuthWalletSuccess) async {
    void onAuthAndTotpSuccess(bool isAuthenticatedSuccessfully,
        {AuthPageState? auth}) async {
      if (isAuthenticatedSuccessfully) {
        onAuthWalletSuccess(true);
        auth != null ? auth.close() : null;
        await loadWallet(wallet);
        return;
      }

      onAuthWalletSuccess(false);
    }

    // Desktop/password auth -> walletUnlockLoadable Route with wallet values as params
    if (SettingsStoreBase.walletPasswordDirectInput) {
      _authService.authenticateAction(
        context,
        // Desktop: every wallet file has a different password,
        // so, when switching, always require auth
        alwaysRequireAuth: true,
        authRoute: Routes.walletUnlockLoadable,
        authArguments: WalletUnlockArguments(
            callback: (isAuthenticatedSuccessfully, auth) =>
                _authService.onAuthSuccess(isAuthenticatedSuccessfully, auth,
                    onAuthAndTotpSuccess: (success) =>
                        onAuthAndTotpSuccess(success, auth: auth)),
            walletName: wallet.name,
            walletType: wallet.type),
        onAuthAndTotpSuccess: onAuthAndTotpSuccess,
      );

      return;
    }

    // Mobile/PIN auth -> regular Auth Route
    _authService.authenticateAction(context,
        onAuthAndTotpSuccess: onAuthAndTotpSuccess);
  }
}
