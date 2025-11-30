import 'dart:async';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/entities/wallet_group.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
import 'package:cake_wallet/entities/wallet_manager.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
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
    this._walletManager,
    this.fiatConversionStore,
  )   : wallets = ObservableList<WalletListItem>(),
        multiWalletGroups = ObservableList<WalletGroup>(),
        singleWalletsList = ObservableList<WalletListItem>(),
        expansionTileStateTrack = ObservableMap<int, bool>(),
        cachedBalances = ObservableList<BalanceCache>(),
        cacheUpdateStatuses = ObservableList<bool>() {
    setOrderType(_appStore.settingsStore.walletListOrder);
    updateList();

    _updateFiatStore();
    Timer.periodic(
      Duration(seconds: 5),
      (timer) => _updateFiatStore(),
    );
  }

  final FiatConversionStore fiatConversionStore;

  @observable
  ObservableList<WalletListItem> wallets;

  @observable
  ObservableList<BalanceCache> cachedBalances;

  @observable
  ObservableList<bool> cacheUpdateStatuses;

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

  String cachedBalanceFor(CryptoCurrency currency) => cachedBalances
      .where((element) =>
          (element.tag == currency.tag || element.tag == "" && currency.tag == null) &&
          element.title == currency.title)
      .first
      .cachedBalance;

  Future<void> _updateFiatStoreForCurrency(CryptoCurrency currency) async {
    fiatConversionStore.prices[currency] = await FiatConversionService.fetchPrice(
        crypto: currency,
        fiat: _appStore.settingsStore.fiatCurrency,
        torOnly: _appStore.settingsStore.fiatApiMode == FiatApiMode.torOnly);
  }

  Future<void> _updateFiatStore() async {
    for (final wallet in wallets) {
      final currency = walletTypeToCryptoCurrency(wallet.type);
      _updateFiatStoreForCurrency(currency);
    }
  }

  String fiatCachedBalanceFor(CryptoCurrency currency) {
    if (fiatConversionStore.prices[currency] == null) {
      _updateFiatStoreForCurrency(currency);
    }

    final price = fiatConversionStore.prices[currency];
    return calculateFiatAmount(cryptoAmount: cachedBalanceFor(currency), price: price);
  }

  String totalFiatBalance() {
    double ret = 0;

    for (final wallet in wallets) {
      ret += double.parse(fiatCachedBalanceFor(walletTypeToCryptoCurrency(wallet.type)));
    }

    return ret.toString();
  }

  @computed
  bool get shouldRequireTOTP2FAForAccessingWallet =>
      _appStore.settingsStore.shouldRequireTOTP2FAForAccessingWallet;

  @computed
  bool get shouldRequireTOTP2FAForCreatingNewWallets =>
      _appStore.settingsStore.shouldRequireTOTP2FAForCreatingNewWallets;

  @computed
  FiatCurrency get fiatCurrency => _appStore.settingsStore.fiatCurrency;

  final AppStore _appStore;
  final WalletManager _walletManager;
  final WalletLoadingService _walletLoadingService;

  WalletType get currentWalletType => _appStore.wallet!.type;

  Future<bool> requireHardwareWalletConnection(WalletListItem walletItem) async =>
      _walletLoadingService.requireHardwareWalletConnection(walletItem.type, walletItem.name);

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
      cacheUpdateStatuses.clear();

      final list = await WalletInfo.getAll();

      for (var info in list) {
        wallets.add(await convertWalletInfoToWalletListItem(info));
        cachedBalances.addAll(await BalanceCache.fromWalletId(info.internalId));
        cacheUpdateStatuses.add(true);
      }

      //========== Split into shared seed groups and single wallets list
      await _walletManager.updateWalletGroups();

      final walletGroupsFromManager = _walletManager.walletGroups;

      for (var group in walletGroupsFromManager) {
        if (group.wallets.length == 1) {
          singleWalletsList.add(await convertWalletInfoToWalletListItem(group.wallets.first));
          continue;
        }

        multiWalletGroups.add(group);
      }
    } finally {
      isUpdating = false;
    }
  }

  @action
  Future<void> refreshCachedBalances() async {
    for (final wallet in wallets) {
      cacheUpdateStatuses[wallets.indexOf(wallet)] = false;

      final tmpWallet = await _walletLoadingService.load(wallet.type, wallet.name);
      await tmpWallet.startSync();
      while (tmpWallet.syncStatus.progress() < 1.0) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      await tmpWallet.close();

      cacheUpdateStatuses[wallets.indexOf(wallet)] = true;
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
            wiList[i].sortOrder = i + oldI;
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

  Future<WalletListItem> convertWalletInfoToWalletListItem(WalletInfo info) async {
    return WalletListItem(
      name: info.name,
      type: info.type,
      key: info.id,
      isCurrent: info.name == _appStore.wallet?.name && info.type == _appStore.wallet?.type,
      isEnabled: availableWalletTypes.contains(info.type),
      isTestnet: info.network?.toLowerCase().contains('testnet') ?? false,
      isHardware: info.isHardwareWallet,
    );
  }
}
