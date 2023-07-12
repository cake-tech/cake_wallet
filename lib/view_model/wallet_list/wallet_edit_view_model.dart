import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';

part 'wallet_edit_view_model.g.dart';

class WalletEditViewModel = WalletEditViewModelBase with _$WalletEditViewModel;

abstract class WalletEditViewModelState {}

class WalletEditViewModelInitialState extends WalletEditViewModelState {}

class WalletEditRenamePending extends WalletEditViewModelState {}

class WalletEditDeletePending extends WalletEditViewModelState {}

abstract class WalletEditViewModelBase with Store {
  WalletEditViewModelBase(this._walletListViewModel, this._walletLoadingService)
      : state = WalletEditViewModelInitialState(),
        newName = '';

  @observable
  WalletEditViewModelState state;

  @observable
  String newName;

  final WalletListViewModel _walletListViewModel;
  final WalletLoadingService _walletLoadingService;

  @action
  Future<void> changeName(WalletListItem walletItem) async {
    state = WalletEditRenamePending();
    await _walletLoadingService.renameWallet(
        walletItem.type, walletItem.name, newName);
    _walletListViewModel.updateList();
  }

  @action
  Future<void> remove(WalletListItem wallet) async {
    state = WalletEditDeletePending();
    final walletService = getIt.get<WalletService>(param1: wallet.type);
    await walletService.remove(wallet.name);
    resetState();
    _walletListViewModel.updateList();
  }

  @action
  void resetState() {
    state = WalletEditViewModelInitialState();
  }
}
