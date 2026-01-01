import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/db/sqlite.dart' show db;

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(
    this.appStore,
    this._walletLoadingService,
    this._walletManager,
  )   : wallets = ObservableList<WalletListItem>(),
        multiWalletGroups = ObservableList<WalletGroup>(),
        singleWalletsList = ObservableList<WalletListItem>(),
        expansionTileStateTrack = ObservableMap<int, bool>() {
    setOrderType(appStore.settingsStore.walletListOrder);
    updateList();
  }

  @observable
  ObservableList<WalletListItem> wallets;

  // @observable
  // ObservableList<WalletGroup> walletGroups;

  @observable
  ObservableList<WalletGroup> multiWalletGroups;

  @observable
  ObservableList<WalletListItem> singleWalletsList;

  @observable
  ObservableMap<int, bool> expansionTileStateTrack;

  @action
  void updateTileState(int index, bool isExpanded) {
    if (expansionTileStateTrack.containsKey(index)) {
      expansionTileStateTrack.update(index, (value) => isExpanded);
    } else {
      expansionTileStateTrack.addEntries({index: isExpanded}.entries);
    }
  }

  @computed
  bool get shouldRequireTOTP2FAForAccessingWallet =>
      appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;

  @computed
  bool get shouldRequireTOTP2FAForCreatingNewWallets =>
      appStore.settingsStore.shouldRequireTOTP2FAForCreatingNewWallets;

  final AppStore appStore;
  final WalletManager _walletManager;
  final WalletLoadingService _walletLoadingService;

  WalletType get currentWalletType => appStore.wallet!.type;

  Set<WalletType> getTypesInGroup(WalletGroup group) {
    final types = <WalletType>{};
    for (var wallet in group.wallets) {
      types.add(wallet.type);
    }
    return types;
  }

  Future<bool> requireHardwareWalletConnection(WalletListItem walletItem) async =>
      _walletLoadingService.requireHardwareWalletConnection(
          walletItem.type, walletItem.name);

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    if (walletItem.type == WalletType.haven) {
      return;
    }
    // bool switchingToSameWalletType = walletItem.type == _appStore.wallet?.type;
    // await _appStore.wallet?.close(shouldCleanup: !switchingToSameWalletType);
    final wallet = await _walletLoadingService.load(walletItem.type, walletItem.name);
    await appStore.changeCurrentWallet(wallet);
    updateList();
  }

  FilterListOrderType? get orderType => appStore.settingsStore.walletListOrder;

  bool get ascending => appStore.settingsStore.walletListAscending;

  
  bool isUpdating = false;
  @action
  Future<void> updateList() async {
    if (isUpdating) {
      return;
    }
    isUpdating = true;
    try {
      wallets.clear();
      multiWalletGroups.clear();
      singleWalletsList.clear();

      final list = await WalletInfo.getAll();

      for (var info in list) {
        wallets.add(convertWalletInfoToWalletListItem(info));
      }

      //========== Split into shared seed groups and single wallets list
      await _walletManager.updateWalletGroups();

      final walletGroupsFromManager = _walletManager.walletGroups;

      for (var group in walletGroupsFromManager) {
        if (group.wallets.length == 1) {
          singleWalletsList.add(convertWalletInfoToWalletListItem(group.wallets.first));
          continue;
        }

        multiWalletGroups.add(group);
      }
    } finally {
      isUpdating = false;
    }
  }

  Future<void> reorderAccordingToWalletList() async {
    if (wallets.isEmpty) {
      await updateList();
      return;
    }

    appStore.settingsStore.walletListOrder = FilterListOrderType.Custom;

    // make a copy of the walletInfoSource:
    List<WalletInfo> wiList = await WalletInfo.getAll();

    // Reorder single wallets using the singleWalletsList
    int oldI = 0;
    for (WalletListItem wallet in singleWalletsList) {
      for (int i = 0; i < wiList.length; i++) {
        if (wiList[i].id == wallet.key) {
          oldI++;
          wiList[i].sortOrder = oldI;
          await wiList[i].save();
          break;
        }
      }
    }

    // Reorder wallets within multi-wallet groups
    for (WalletGroup group in multiWalletGroups) {
      for (WalletInfo walletInfo in group.wallets) {
        for (int i = 0; i < wiList.length; i++) {
          if (wiList[i].name == walletInfo.name) {
            wiList[i].sortOrder = i+oldI;
            await wiList[i].save();
            wiList.removeAt(i);
            break;
          }
        }
      }
    }

    // Rebuild the list of wallets and groups
    await updateList();
  }

  Future<void> sortGroupByType() async {
    // sort the wallets by type:
    List<WalletInfo> wiList = await WalletInfo.getAll();
    if (ascending) {
      wiList.sort((a, b) => a.type.toString().compareTo(b.type.toString()));
    } else {
      wiList.sort((a, b) => b.type.toString().compareTo(a.type.toString()));
    }
    for (int i = 0; i < wiList.length; i++) {
      wiList[i].sortOrder = i;
      await wiList[i].save();
    }
    await updateList();
  }

  Future<void> sortAlphabetically() async {
    // sort the wallets alphabetically:
    List<WalletInfo> wiList = await WalletInfo.getAll();
    if (ascending) {
      wiList.sort((a, b) => a.name.compareTo(b.name));
    } else {
      wiList.sort((a, b) => b.name.compareTo(a.name));
    }
    for (int i = 0; i < wiList.length; i++) {
      wiList[i].sortOrder = i;
      await wiList[i].save();
    }
    await updateList();
  }

  Future<void> sortByCreationDate() async {
    // sort the wallets by creation date:
    List<WalletInfo> wiList = await WalletInfo.getAll();
    if (ascending) {
      wiList.sort((a, b) => a.date.compareTo(b.date));
    } else {
      wiList.sort((a, b) => b.date.compareTo(a.date));
    }
    for (int i = 0; i < wiList.length; i++) {
      wiList[i].sortOrder = i;
      await wiList[i].save();
    }

    updateList();
  }

  void setAscending(bool ascending) {
    appStore.settingsStore.walletListAscending = ascending;
  }

  Future<void> setOrderType(FilterListOrderType? type) async {
    if (type == null) return;

    appStore.settingsStore.walletListOrder = type;

    switch (type) {
      case FilterListOrderType.CreationDate:
        await sortByCreationDate();
        break;
      case FilterListOrderType.Alphabetical:
        await sortAlphabetically();
        break;
      case FilterListOrderType.GroupByType:
        await sortGroupByType();
        break;
      case FilterListOrderType.Custom:
        await reorderAccordingToWalletList();
        break;
    }
  }

  WalletListItem convertWalletInfoToWalletListItem(WalletInfo info) {
    return WalletListItem(
      name: info.name,
      type: info.type,
      key: info.id,
      internalId: info.internalId,
      isReady: info.isReady,
      isCurrent: info.name == appStore.wallet?.name &&
          info.type == appStore.wallet?.type,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
      isHardware: info.isHardwareWallet,
    );
  }
}
