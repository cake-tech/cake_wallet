import 'dart:async';

import "package:cake_wallet/core/key_service.dart";
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import "package:cake_wallet/entities/wallet_group_service.dart";
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import "package:cw_core/wallet_service.dart";
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
    this._appStore,
    this._walletLoadingService,
    this._walletGroupService,
    this._keyService,
    this._walletServiceFactory,
  )   : wallets = ObservableList<WalletListItem>(),
        multiWalletGroups = ObservableList<WalletGroup>.of(_walletGroupService.groups),
        expansionTileStateTrack = ObservableMap<int, bool>() {
    _groupsSub = _walletGroupService.watch().listen(_setGroups);

    setOrderType(_appStore.settingsStore.walletListOrder);
    updateList();
    reaction((_) => _appStore.wallet, (_) => updateList());
  }

  final AppStore _appStore;
  final WalletLoadingService _walletLoadingService;
  final WalletGroupService _walletGroupService;
  final KeyService _keyService;
  final WalletService Function(WalletType type) _walletServiceFactory;

  StreamSubscription<List<WalletGroup>>? _groupsSub;
  bool _isDeletingGroup = false;

  @observable
  ObservableList<WalletListItem> wallets;

  @observable
  ObservableList<WalletGroup> multiWalletGroups;

  @observable
  ObservableMap<int, bool> expansionTileStateTrack;

  @action
  void _setGroups(List<WalletGroup> groups) => multiWalletGroups
    ..clear()
    ..addAll(groups);

  bool groupContainsCurrentWallet(WalletGroup group) =>
      group.wallets.any((w) => w.id == _appStore.wallet?.walletInfo.id);


  Future<void> deleteGroup(WalletGroup group) async {
    if (_isDeletingGroup) return;
    if (groupContainsCurrentWallet(group)) {
      throw StateError("Cannot delete the group of the currently open wallet");
    }

    _isDeletingGroup = true;
    try {
      for (final info in group.wallets) {
        await _walletServiceFactory(info.type).remove(info);
        await _keyService.deleteWalletPasswordForWallet(info);
      }
      await _walletGroupService.deleteGroupIfEmpty(group.groupKey);
    } finally {
      _isDeletingGroup = false;
      await updateList();
    }
  }

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

  WalletType get currentWalletType => _appStore.wallet!.type;

  Future<bool> requireHardwareWalletConnection(WalletListItem walletItem) async =>
      _walletLoadingService.requireHardwareWalletConnection(walletItem.walletInfo);

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    if (walletItem.type == WalletType.haven) {
      return;
    }

    final wallet = await _walletLoadingService.load(walletItem.walletInfo);
    await _appStore.changeCurrentWallet(wallet);
    updateList();
  }

  FilterListOrderType? get orderType => _appStore.settingsStore.walletListOrder;

  bool get ascending => _appStore.settingsStore.walletListAscending;

  /// Serializes updateList() calls: each caller waits for the previous one to finish, then runs.
  ///
  /// This basically ensures that all calls to updateList() are executed.
  Future<void> _lastUpdate = Future.value();

  @action
  Future<void> updateList() async {
    final waitFor = _lastUpdate;
    final done = Completer<void>();
    _lastUpdate = done.future;
    await waitFor;

    try {
      wallets
        ..clear()
        ..addAll((await WalletInfo.getAll()).map(convertWalletInfoToWalletListItem));

      // Rebuilds groups in the service; its emission refills multiWalletGroups via _setGroups.
      await _walletGroupService.updateWalletGroups();
    } finally {
      done.complete();
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

    for (WalletGroup group in multiWalletGroups) {
      for (WalletInfo walletInfo in group.wallets) {
        for (int i = 0; i < wiList.length; i++) {
          if (wiList[i].id == walletInfo.id) {
            wiList[i].sortOrder = i;
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
    String formatedName = info.name;
    final list = info.name.split('_');
    if (list.length > 1) {
      formatedName = list.last;
    }
    return WalletListItem(
      walletInfo: info,
      name: info.name,
      formatedName: formatedName,
      type: info.type,
      key: info.id,
      isCurrent: info.id == _appStore.wallet?.walletInfo.id,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
      isHardware: info.isHardwareWallet,
    );
  }

  void dispose() => _groupsSub?.cancel();
}
