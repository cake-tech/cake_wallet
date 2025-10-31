import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/wallet_types.g.dart';

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(
    this._appStore,
    this._walletLoadingService,
    this._walletManager,
  )   : wallets = ObservableList<WalletListItem>(),
        multiWalletGroups = ObservableList<WalletGroup>(),
        singleWalletsList = ObservableList<WalletListItem>(),
        expansionTileStateTrack = ObservableMap<int, bool>() {
    setOrderType(_appStore.settingsStore.walletListOrder);
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
      _appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;

  @computed
  bool get shouldRequireTOTP2FAForCreatingNewWallets =>
      _appStore.settingsStore.shouldRequireTOTP2FAForCreatingNewWallets;

  final AppStore _appStore;
  final WalletManager _walletManager;
  final WalletLoadingService _walletLoadingService;

  WalletType get currentWalletType => _appStore.wallet!.type;

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
    await _appStore.changeCurrentWallet(wallet);
  }

  FilterListOrderType? get orderType => _appStore.settingsStore.walletListOrder;

  bool get ascending => _appStore.settingsStore.walletListAscending;

  
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

    _appStore.settingsStore.walletListOrder = FilterListOrderType.Custom;

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
    _appStore.settingsStore.walletListAscending = ascending;
  }

  Future<void> setOrderType(FilterListOrderType? type) async {
    if (type == null) return;

    _appStore.settingsStore.walletListOrder = type;

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
      isCurrent: info.name == _appStore.wallet?.name &&
          info.type == _appStore.wallet?.type,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
      isHardware: info.isHardwareWallet,
    );
  }
}
