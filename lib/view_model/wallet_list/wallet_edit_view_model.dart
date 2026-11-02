import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/wallet_manager.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_item.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_service.dart";
import "package:mobx/mobx.dart";

part "wallet_edit_view_model.g.dart";

class WalletEditViewModel = WalletEditViewModelBase with _$WalletEditViewModel;

abstract class WalletEditViewModelState {}

class WalletEditViewModelInitialState extends WalletEditViewModelState {}

class WalletEditRenamePending extends WalletEditViewModelState {}

class WalletEditDeletePending extends WalletEditViewModelState {}

abstract class WalletEditViewModelBase with Store {
  WalletEditViewModelBase(this._walletListViewModel, this._walletManager)
      : state = WalletEditViewModelInitialState(),
        newName = "";

  @observable
  WalletEditViewModelState state;

  @observable
  String newName;

  final WalletListViewModel _walletListViewModel;
  final WalletManager _walletManager;

  @action
  Future<void> renameGroup(String walletGroupKey) async {
    final name = newName.trim();
    if (name.isEmpty) return;

    state = WalletEditRenamePending();
    try {
      await _walletManager.updateWalletGroups();
      // TODO(serhii): also write the name to the walletGroup row when the UI moves to DB groups.
      await _walletManager.setGroupName(walletGroupKey, name);
      await _walletListViewModel.updateList();
    } finally {
      resetState();
    }
  }

  @action
  Future<void> remove(WalletListItem item) async {
    state = WalletEditDeletePending();
    try {
      final walletInfo = await WalletInfo.getById(item.key);
      if (walletInfo == null) return; // already removed

      await getIt.get<WalletService>(param1: walletInfo.type).remove(walletInfo);
      await _walletListViewModel.updateList();
    } finally {
      resetState();
    }
  }

  @action
  void resetState() => state = WalletEditViewModelInitialState();
}
