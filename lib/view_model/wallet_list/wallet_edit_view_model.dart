import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/wallet_group_manager.dart";
import "package:cake_wallet/new-ui/entries/omnichain_wallet/wallet_icon.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_item.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart";
import "package:cw_core/wallet_service.dart";
import "package:mobx/mobx.dart";

part "wallet_edit_view_model.g.dart";

class WalletEditViewModel = WalletEditViewModelBase with _$WalletEditViewModel;

abstract class WalletEditViewModelState {}

class WalletEditViewModelInitialState extends WalletEditViewModelState {}

class WalletEditRenamePending extends WalletEditViewModelState {}

class WalletEditDeletePending extends WalletEditViewModelState {}

abstract class WalletEditViewModelBase with Store {
  WalletEditViewModelBase(
    this._walletListViewModel,
    this._walletLoadingService,
    this._walletManager,
  )   : state = WalletEditViewModelInitialState(),
        newName = "";

  @observable
  WalletEditViewModelState state;

  @observable
  String newName;

  final WalletListViewModel _walletListViewModel;
  final WalletLoadingService _walletLoadingService;
  final WalletGroupManager _walletManager;

  @action
  Future<void> changeName(
      WalletListItem walletItem, {
        String? password,
        String? walletGroupKey,
        bool isWalletGroup = false,
      }) async {
    state = WalletEditRenamePending();

    if (isWalletGroup) {
      await _walletManager.updateWalletGroups();
      await _walletManager.setGroupName(walletGroupKey!, newName);
    } else {
      await _walletLoadingService.renameWallet(
        walletItem.walletInfo,
        newName,
        password: password,
      );
    }

    _walletListViewModel.updateList();
  }

  @action
  Future<void> changeIcon(String walletGroupKey, WalletIcon icon) async {
    await _walletManager.updateWalletGroups();

    _walletManager.setGroupIcon(walletGroupKey, icon);

    _walletListViewModel.updateList();
  }

  @action
  Future<void> remove(WalletListItem wallet) async {
    state = WalletEditDeletePending();
    final walletService = getIt.get<WalletService>(param1: wallet.type);
    await walletService.remove(wallet.walletInfo);
    resetState();
    _walletListViewModel.updateList();
  }

  @action
  void resetState() {
    state = WalletEditViewModelInitialState();
  }
}
