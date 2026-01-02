import 'dart:async';

import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'wallet_groups_display_view_model.g.dart';

class WalletGroupsDisplayViewModel = WalletGroupsDisplayViewModelBase
    with _$WalletGroupsDisplayViewModel;

abstract class WalletGroupsDisplayViewModelBase with Store {
  WalletGroupsDisplayViewModelBase(
    this._appStore,
    this._walletLoadingService,
    this._walletManager,
    this.walletListViewModel, {
    required this.type,
  })  : isFetchingMnemonic = false {
    reaction((_) => _appStore.wallet, (_) => unawaited(updateWalletInfoSourceList()));
    unawaited(updateWalletInfoSourceList());
  }

  final WalletType type;
  final AppStore _appStore;
  final WalletManager _walletManager;
  final WalletLoadingService _walletLoadingService;
  final WalletListViewModel walletListViewModel;

  @observable
  ObservableList<WalletGroup> multiWalletGroups = ObservableList<WalletGroup>();

  @observable
  ObservableList<WalletInfo> singleWalletsList = ObservableList<WalletInfo>();

  @observable
  WalletGroup? selectedWalletGroup;

  @observable
  WalletInfo? selectedSingleWallet;

  @observable
  bool isFetchingMnemonic;

  @computed
  bool get hasNoFilteredWallet {
    return singleWalletsList.isEmpty && multiWalletGroups.isEmpty;
  }

  @action
  Future<String?> getSelectedWalletMnemonic() async {
    WalletListItem walletToUse;

    bool isGroupSelected = selectedWalletGroup != null;

    if (isGroupSelected) {
      walletToUse = convertWalletInfoToWalletListItem(selectedWalletGroup!.wallets.first);
    } else {
      walletToUse = convertWalletInfoToWalletListItem(selectedSingleWallet!);
    }

    try {
      isFetchingMnemonic = true;
      final wallet = await _walletLoadingService.load(
        walletToUse.type,
        walletToUse.name,
      );

      return wallet.seed;
    } catch (e) {
      return null;
    } finally {
      isFetchingMnemonic = false;
    }
  }

  @action
  void selectWalletGroup(WalletGroup walletGroup) {
    selectedWalletGroup = walletGroup;
    selectedSingleWallet = null;
  }

  @action
  void selectSingleWallet(WalletInfo singleWallet) {
    selectedSingleWallet = singleWallet;
    selectedWalletGroup = null;
  }

  @action
  Future<void> updateWalletInfoSourceList() async {
    List<WalletGroup> wallets = [];

    multiWalletGroups.clear();
    singleWalletsList.clear();

    await _walletManager.updateWalletGroups();

    final walletGroups = _walletManager.walletGroups;

    // Iterate through the wallet groups to filter and categorize wallets
    for (var group in walletGroups) {
      // Handle group wallet filtering
      bool shouldExcludeGroup = false;
      for (final wallet in group.wallets) {
        // Check for non-BIP39 wallet types
        bool isNonBIP39Wallet = !isBIP39Wallet(wallet.type);

        // Check for nano derivation type
        final di = await wallet.getDerivationInfo();
        bool isNanoDerivationType = wallet.type == WalletType.nano &&
            di.derivationType == DerivationType.nano;

        // Check for electrum derivation type
        bool isElectrumDerivationType =
            (wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin) &&
                di.derivationType == DerivationType.electrum;

        // Check that selected wallet type is not present already in group
        bool isSameTypeAsSelectedWallet = wallet.type == type;

        bool isNonSeedWallet = wallet.isNonSeedWallet;

        bool isNotMoneroBip39Wallet = wallet.type == WalletType.monero &&
            di.derivationType != DerivationType.bip39;

        // Exclude if any of these conditions are true
        shouldExcludeGroup = shouldExcludeGroup ||
          isNonBIP39Wallet ||
          isNanoDerivationType ||
          isElectrumDerivationType ||
          isSameTypeAsSelectedWallet ||
          isNonSeedWallet ||
          isNotMoneroBip39Wallet;
      }

      if (shouldExcludeGroup) continue;

      // If the group passes the filters, add it to the wallets list
      wallets.add(group);
    }

    for (var group in wallets) {
      if (group.wallets.length == 1) {
        singleWalletsList.add(group.wallets.first);
      } else {
        multiWalletGroups.add(group);
      }
    }
  }

  WalletListItem convertWalletInfoToWalletListItem(WalletInfo info) {
    return WalletListItem(
      name: info.name,
      type: info.type,
      key: info.id,
      internalId: info.internalId,
      isCurrent: info.name == _appStore.wallet?.name && info.type == _appStore.wallet?.type,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
      isHardware: info.isHardwareWallet,
    );
  }
}
