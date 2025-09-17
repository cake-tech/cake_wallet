import 'dart:async';

import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:mobx/mobx.dart';

part 'wallet_switcher_view_model.g.dart';

class WalletSwitcherViewModel = WalletSwitcherViewModelBase with _$WalletSwitcherViewModel;

abstract class WalletSwitcherViewModelBase with Store {
  WalletSwitcherViewModelBase({
    required this.appStore,
    required this.walletLoadingService,
  });

  final AppStore appStore;
  final WalletLoadingService walletLoadingService;

  @observable
  WalletInfo? selectedWallet;

  @observable
  bool isProcessing = false;

  @action
  Future<List<WalletInfo>> getWallets(WalletType? walletType) async {
    final wiList = await WalletInfo.getAll();
    if (walletType == null) {
      return wiList;
    }

    return wiList.where((wallet) => wallet.type == walletType).toList();
  }

  @action
  void selectWallet(WalletInfo walletInfo) => selectedWallet = walletInfo;

  @action
  Future<bool> switchToSelectedWallet() async {
    if (selectedWallet == null) return false;

    try {
      isProcessing = true;

      final wallet = await walletLoadingService.load(selectedWallet!.type, selectedWallet!.name);

      await appStore.changeCurrentWallet(wallet);

      return true;
    } catch (e) {
      printV('Failed to switch wallet: $e');
      return false;
    } finally {
      isProcessing = false;
    }
  }
}
