import 'dart:async';

import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/new_wallet_arguments.dart";
import 'package:cake_wallet/core/wallet_loading_service.dart';
import "package:cake_wallet/entities/seed_type.dart";
import 'package:cake_wallet/entities/wallet_group.dart';
import "package:cake_wallet/core/services/wallet_group_service.dart";
import 'package:cake_wallet/new-ui/utils/omnichain_compatibility.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import "package:cake_wallet/view_model/wallet_new_vm.dart";
import 'package:cake_wallet/wallet_types.g.dart';
import "package:cw_core/generate_name.dart";
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
    required WalletNewVM Function(NewWalletArguments) walletNewVMBuilder,
  })  : _walletNewVMBuilder = walletNewVMBuilder,
        isFetchingMnemonic = false {
    reaction((_) => _appStore.wallet, (_) => unawaited(updateWalletInfoSourceList()));
    unawaited(updateWalletInfoSourceList());
  }

  final WalletType type;
  final AppStore _appStore;
  final WalletGroupService _walletManager;
  final WalletLoadingService _walletLoadingService;
  final WalletListViewModel walletListViewModel;

  final WalletNewVM Function(NewWalletArguments) _walletNewVMBuilder;

  @observable
  bool isCreatingWallet = false;

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
  bool get hasNoFilteredWallet => singleWalletsList.isEmpty && multiWalletGroups.isEmpty;

  /// Throws [GroupNotOmnichainCompatibleException] if the selected group/wallet's seed
  /// can't be reused for another network.
  @action
  Future<String?> getSelectedWalletMnemonic() async {
    final WalletInfo walletInfo;

    if (selectedWalletGroup != null) {
      final group = selectedWalletGroup!;
      if (!await isOmnichainCompatibleGroup(group.wallets)) {
        throw GroupNotOmnichainCompatibleException(group.groupKey);
      }
      // Seed source: a ready wallet (placeholders have no seed); all of them passed the rule.
      walletInfo = group.wallets.firstWhere((w) => w.isReady);
    } else {
      walletInfo = selectedSingleWallet!;
      if (!await isOmnichainCompatible(walletInfo)) {
        throw GroupNotOmnichainCompatibleException(_walletManager.resolveGroupKey(walletInfo));
      }
    }

    // Already open: read its seed instead of opening a second copy.
    final current = _appStore.wallet;
    if (current != null && current.walletInfo.id == walletInfo.id) {
      return current.seed;
    }

    try {
      isFetchingMnemonic = true;
      final wallet = await _walletLoadingService.load(walletInfo);
      try {
        return wallet.seed;
      } finally {
        await wallet.close(shouldCleanup: false);
      }
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

    final walletGroups = List<WalletGroup>.from(_walletManager.groups);

    // Iterate through the wallet groups to filter and categorize wallets
    for (var group in walletGroups) {
      // A group that already has the selected type can't get another wallet of it.
      final hasSelectedType = group.wallets.any((wallet) => wallet.type == type);
      if (hasSelectedType) continue;

      // Its seed is reused for the new wallet, so the group must pass the omnichain rule
      // (computed by WalletGroupService.updateWalletGroups above).
      if (!group.canManageNetworks) continue;

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

  WalletListItem convertWalletInfoToWalletListItem(WalletInfo info) => WalletListItem(
        walletInfo: info,
        name: info.name,
        type: info.type,
        key: info.id,
        isCurrent: info.id == _appStore.wallet?.walletInfo.id,
        isEnabled: availableWalletTypes.contains(info.type),
        isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
        isHardware: info.isHardwareWallet,
      );

  @action
  Future<String?> addWalletToSelectedGroup(String mnemonic) async {
    isCreatingWallet = true;
    try {
      final walletNewVM = _walletNewVMBuilder(NewWalletArguments(
        type: type,
        mnemonic: mnemonic,
        isChildWallet: true,
        parentGroupId: selectedWalletGroup?.groupKey ?? selectedSingleWallet?.groupId,
      ));

      walletNewVM.seedSettingsViewModel.setMoneroSeedType(MoneroSeedType.bip39);
      walletNewVM.name = await _generateUniqueName(walletNewVM);

      await walletNewVM.create(
        options: walletNewVM.hasLanguageSelector ? ["English", MoneroSeedType.bip39] : null,
      );

      final state = walletNewVM.state;
      return state is FailureState ? state.error : null;
    } catch (e) {
      return e.toString();
    } finally {
      isCreatingWallet = false;
    }
  }

  Future<String> _generateUniqueName(WalletNewVM walletNewVM) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final name = await generateName();
      if (!await walletNewVM.nameExists(name)) return name;
    }
    throw Exception("Could not generate a unique wallet name");
  }
}
