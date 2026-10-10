import 'package:cake_wallet/entities/wallet_manager.dart';
import "package:cake_wallet/new-ui/services/wallet_pool_service.dart";
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:mobx/mobx.dart';
import "package:cw_core/wallet_info.dart";
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';

part 'wallet_edit_view_model.g.dart';

class WalletEditViewModel = WalletEditViewModelBase with _$WalletEditViewModel;

abstract class WalletEditViewModelState {}

class WalletEditViewModelInitialState extends WalletEditViewModelState {}

class WalletEditRenamePending extends WalletEditViewModelState {}

class WalletEditDeletePending extends WalletEditViewModelState {}

abstract class WalletEditViewModelBase with Store {
  WalletEditViewModelBase(
    this._walletListViewModel,
    this._walletPoolService,
    this._walletManager,
  )   : state = WalletEditViewModelInitialState(),
        newName = '';

  @observable
  WalletEditViewModelState state;

  @observable
  String newName;

  final WalletListViewModel _walletListViewModel;
  final WalletPoolService _walletPoolService;
  final WalletManager _walletManager;

  @action
  Future<void> changeName(
    WalletListItem walletItem, {
    String? password,
    String? walletGroupKey,
    bool isWalletGroup = false,
  }) async {
    state = WalletEditRenamePending();

    try {
      if (isWalletGroup) {
        await _walletManager.updateWalletGroups();

        _walletManager.setGroupName(walletGroupKey!, newName);
      } else {
        await _walletPoolService.rename(
          WalletKey(walletItem.name, walletItem.type),
          newName,
          password: password,
        );
      }
    } catch (_) {
      resetState();
      rethrow;
    }

    _walletListViewModel.updateList();
  }

  @action
  Future<void> remove(WalletListItem wallet) async {
    state = WalletEditDeletePending();

    try {
      await _walletPoolService.remove(WalletKey(wallet.name, wallet.type));
    } finally {
      resetState();
    }
    _walletListViewModel.updateList();
  }

  @action
  void resetState() {
    state = WalletEditViewModelInitialState();
  }
}
