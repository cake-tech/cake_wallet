import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(
    this._walletInfoSource,
    this._appStore,
    this._walletLoadingService,
    this._walletManager,
  )   : wallets = ObservableList<WalletListItem>(),
        multiWalletGroups = ObservableList<WalletGroup>(),
        singleWalletsList = ObservableList<WalletListItem>(),
        expansionTileStateTrack = ObservableMap<int, bool>() {
    setOrderType(_appStore.settingsStore.walletListOrder);
    reaction((_) => _appStore.wallet, (_) => updateList());
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
  final Box<WalletInfo> _walletInfoSource;
  final WalletLoadingService _walletLoadingService;

  WalletType get currentWalletType => _appStore.wallet!.type;

  bool requireHardwareWalletConnection(WalletListItem walletItem) =>
      _walletLoadingService.requireHardwareWalletConnection(
          walletItem.type, walletItem.name);

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    // bool switchingToSameWalletType = walletItem.type == _appStore.wallet?.type;
    // await _appStore.wallet?.close(shouldCleanup: !switchingToSameWalletType);
    final wallet = await _walletLoadingService.load(walletItem.type, walletItem.name);
    await _appStore.changeCurrentWallet(wallet);
  }

  FilterListOrderType? get orderType => _appStore.settingsStore.walletListOrder;

  bool get ascending => _appStore.settingsStore.walletListAscending;

  @action
  void updateList() {
    wallets.clear();
    multiWalletGroups.clear();
    singleWalletsList.clear();

    wallets.addAll(
      _walletInfoSource.values
          .map((info) => convertWalletInfoToWalletListItem(info)),
    );

    //========== Split into shared seed groups and single wallets list
    _walletManager.updateWalletGroups();

    for (var group in _walletManager.walletGroups) {
      if (group.wallets.length == 1) {
        singleWalletsList
            .add(convertWalletInfoToWalletListItem(group.wallets.first));
      } else {
        multiWalletGroups.add(group);
      }
    }
  }

  Future<void> reorderAccordingToWalletList() async {
    if (wallets.isEmpty) {
      updateList();
      return;
    }

    _appStore.settingsStore.walletListOrder = FilterListOrderType.Custom;

    // make a copy of the walletInfoSource:
    List<WalletInfo> walletInfoSourceCopy = _walletInfoSource.values.toList();
    // delete all wallets from walletInfoSource:
    await _walletInfoSource.clear();

    // Reorder single wallets using the singleWalletsList
    for (WalletListItem wallet in singleWalletsList) {
      for (int i = 0; i < walletInfoSourceCopy.length; i++) {
        if (walletInfoSourceCopy[i].name == wallet.name) {
          await _walletInfoSource.add(walletInfoSourceCopy[i]);
          walletInfoSourceCopy.removeAt(i);
          break;
        }
      }
    }

    // Reorder wallets within multi-wallet groups
    for (WalletGroup group in multiWalletGroups) {
      for (WalletInfo walletInfo in group.wallets) {
        for (int i = 0; i < walletInfoSourceCopy.length; i++) {
          if (walletInfoSourceCopy[i].name == walletInfo.name) {
            await _walletInfoSource.add(walletInfoSourceCopy[i]);
            walletInfoSourceCopy.removeAt(i);
            break;
          }
        }
      }
    }

    // Rebuild the list of wallets and groups
    updateList();
  }

  Future<void> sortGroupByType() async {
    // sort the wallets by type:
    List<WalletInfo> walletInfoSourceCopy = _walletInfoSource.values.toList();
    await _walletInfoSource.clear();
    if (ascending) {
      walletInfoSourceCopy
          .sort((a, b) => a.type.toString().compareTo(b.type.toString()));
    } else {
      walletInfoSourceCopy
          .sort((a, b) => b.type.toString().compareTo(a.type.toString()));
    }
    await _walletInfoSource.addAll(walletInfoSourceCopy);
    updateList();
  }

  Future<void> sortAlphabetically() async {
    // sort the wallets alphabetically:
    List<WalletInfo> walletInfoSourceCopy = _walletInfoSource.values.toList();
    await _walletInfoSource.clear();
    if (ascending) {
      walletInfoSourceCopy.sort((a, b) => a.name.compareTo(b.name));
    } else {
      walletInfoSourceCopy.sort((a, b) => b.name.compareTo(a.name));
    }
    await _walletInfoSource.addAll(walletInfoSourceCopy);
    updateList();
  }

  Future<void> sortByCreationDate() async {
    // sort the wallets by creation date:
    List<WalletInfo> walletInfoSourceCopy = _walletInfoSource.values.toList();
    await _walletInfoSource.clear();
    if (ascending) {
      walletInfoSourceCopy.sort((a, b) => a.date.compareTo(b.date));
    } else {
      walletInfoSourceCopy.sort((a, b) => b.date.compareTo(a.date));
    }
    await _walletInfoSource.addAll(walletInfoSourceCopy);
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
      default:
        await reorderAccordingToWalletList();
        break;
    }
  }

  WalletListItem convertWalletInfoToWalletListItem(WalletInfo info) {
    return WalletListItem(
      name: info.name,
      type: info.type,
      key: info.key,
      isCurrent: info.name == _appStore.wallet?.name &&
          info.type == _appStore.wallet?.type,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
    );
  }
}
