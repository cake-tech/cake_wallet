import 'package:cake_wallet/core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'rescan_view_model.g.dart';

class RescanViewModel = RescanViewModelBase with _$RescanViewModel;

enum RescanWalletState { rescaning, none }

abstract class RescanViewModelBase with Store {
  RescanViewModelBase(this._wallet) {
    state = RescanWalletState.none;
  }

  @observable
  RescanWalletState state;
  final WalletBase _wallet;

  @action
  Future<void> rescanCurrentWallet({int restoreHeight}) async {
    state = RescanWalletState.rescaning;
    await _wallet.rescan(height: restoreHeight);
    state = RescanWalletState.none;
  }
}