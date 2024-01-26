import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/wallet_list_order_types.dart';
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
  ) : wallets = ObservableList<WalletListItem>() {
    setOrderType(_appStore.settingsStore.walletListOrder);
    reaction((_) => _appStore.wallet, (_) => updateList());
    updateList();
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

  WalletType get currentWalletType => _appStore.wallet!.type;

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    final wallet = await _walletLoadingService.load(walletItem.type, walletItem.name);
    await _appStore.changeCurrentWallet(wallet);
  }

  WalletListOrderType? get orderType => _appStore.settingsStore.walletListOrder;

  bool get ascending => _appStore.settingsStore.walletListAscending;

  @action
  void updateList() {
    wallets.clear();
    wallets.addAll(
      _walletInfoSource.values.map(
        (info) => WalletListItem(
          name: info.name,
          type: info.type,
          key: info.key,
          isCurrent: info.name == _appStore.wallet?.name && info.type == _appStore.wallet?.type,
          isEnabled: availableWalletTypes.contains(info.type),
        ),
      ),
    );
  }

  Future<void> reorderAccordingToWalletList() async {
    if (wallets.isEmpty) {
      updateList();
      return;
    }

    _appStore.settingsStore.walletListOrder = WalletListOrderType.Custom;

    // make a copy of the walletInfoSource:
    List<WalletInfo> walletInfoSourceCopy = _walletInfoSource.values.toList();
    // delete all wallets from walletInfoSource:
    await _walletInfoSource.clear();

    // add wallets from wallets list in order of wallets list, by name:
    for (WalletListItem wallet in wallets) {
      for (int i = 0; i < walletInfoSourceCopy.length; i++) {
        if (walletInfoSourceCopy[i].name == wallet.name) {
          await _walletInfoSource.add(walletInfoSourceCopy[i]);
          walletInfoSourceCopy.removeAt(i);
          break;
        }
      }
    }

    updateList();
  }

  Future<void> sortGroupByType() async {
    // sort the wallets by type:
    List<WalletInfo> walletInfoSourceCopy = _walletInfoSource.values.toList();
    await _walletInfoSource.clear();
    if (ascending) {
      walletInfoSourceCopy.sort((a, b) => a.type.toString().compareTo(b.type.toString()));
    } else {
      walletInfoSourceCopy.sort((a, b) => b.type.toString().compareTo(a.type.toString()));
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

  Future<void> setOrderType(WalletListOrderType? type) async {
    if (type == null) return;

    _appStore.settingsStore.walletListOrder = type;

    switch (type) {
      case WalletListOrderType.CreationDate:
        await sortByCreationDate();
        break;
      case WalletListOrderType.Alphabetical:
        await sortAlphabetically();
        break;
      case WalletListOrderType.GroupByType:
        await sortGroupByType();
        break;
      case WalletListOrderType.Custom:
      default:
        await reorderAccordingToWalletList();
        break;
    }
  }
}
