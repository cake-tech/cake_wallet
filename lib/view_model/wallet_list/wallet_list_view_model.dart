import 'package:cake_wallet/core/auth_service.dart';
import 'package:cake_wallet/core/authentication_request_data.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/src/screens/auth/auth_page.dart';
import 'package:cake_wallet/src/screens/wallet_unlock/wallet_unlock_arguments.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
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
    this._authService,
  ) : wallets = ObservableList<WalletListItem>() {
    updateList();
    reaction((_) => _appStore.wallet, (_) => updateList());
  }

  @observable
  ObservableList<WalletListItem> wallets;

  @computed
  bool get shouldRequireTOTP2FAForAccessingWallet =>
      _appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;

  @computed
  bool get shouldRequireTOTP2FAForCreatingNewWallets =>
      _appStore.settingsStore.shouldRequireTOTP2FAForCreatingNewWallets;

  final AppStore _appStore;
  final Box<WalletInfo> _walletInfoSource;
  final WalletLoadingService _walletLoadingService;
  final AuthService _authService;

  WalletType get currentWalletType => _appStore.wallet!.type;

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    final wallet = await _walletLoadingService.load(walletItem.type, walletItem.name);
    _appStore.changeCurrentWallet(wallet);
  }

  @action
  void updateList() {
    wallets.clear();
    wallets.addAll(
      _walletInfoSource.values.map(
        (info) => WalletListItem(
          name: info.name,
          type: info.type,
          key: info.key,
          isCurrent: info.name == _appStore.wallet!.name && info.type == _appStore.wallet!.type,
          isEnabled: availableWalletTypes.contains(info.type),
        ),
      ),
    );
  }

  @action
  Future<void> authWallet(BuildContext context, WalletListItem wallet) async {
    void onAuthAndTotpSuccess(bool isAuthenticatedSuccessfully, {AuthPageState? auth}) async {
      if (isAuthenticatedSuccessfully) {
        auth != null ? auth.close() : null;
        await loadWallet(wallet);
        return;
      }
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
            useTotp: shouldRequireTOTP2FAForAccessingWallet,
            callback: (AuthResponse auth) async {
              if (auth.success) {
                auth.close();
                _appStore.changeCurrentWallet(auth.payload as WalletBase);
                return;
              }

            },
            walletName: wallet.name,
            walletType: wallet.type),
        onAuthSuccess: onAuthAndTotpSuccess,
        conditionToDetermineIfToUse2FA: shouldRequireTOTP2FAForAccessingWallet,
      );

      return;
    }

    // Mobile/PIN auth -> regular Auth Route
    _authService.authenticateAction(context,
        onAuthSuccess: onAuthAndTotpSuccess,
        conditionToDetermineIfToUse2FA: shouldRequireTOTP2FAForAccessingWallet);
  }
}
