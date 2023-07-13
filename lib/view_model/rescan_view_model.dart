import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'rescan_view_model.g.dart';

class RescanViewModel = RescanViewModelBase with _$RescanViewModel;

enum RescanWalletState { rescaning, none }

abstract class RescanViewModelBase with Store {
  RescanViewModelBase(this._wallet)
    : state = RescanWalletState.none,
      isButtonEnabled = false;

  final WalletBase _wallet;

  @observable
  RescanWalletState state;

  @observable
  bool isButtonEnabled;

  @action
  Future<void> rescanCurrentWallet({required int restoreHeight}) async {
    state = RescanWalletState.rescaning;
    await _wallet.rescan(height: restoreHeight);
    _wallet.transactionHistory.clear();
    state = RescanWalletState.none;
  }
}