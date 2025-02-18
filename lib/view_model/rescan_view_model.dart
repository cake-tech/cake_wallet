import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/view_model/silent_payments_scanning_view_model.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

part 'rescan_view_model.g.dart';

class RescanViewModel = RescanViewModelBase with _$RescanViewModel;

enum RescanWalletState { rescaning, none }

abstract class RescanViewModelBase with Store {
  RescanViewModelBase(this.wallet, this._silentPaymentsScanningViewModel)
      : state = RescanWalletState.none,
        isButtonEnabled = false,
        doSingleScan = false;

  final WalletBase wallet;

  final SilentPaymentsScanningViewModel _silentPaymentsScanningViewModel;

  @observable
  RescanWalletState state;

  @observable
  bool isButtonEnabled;

  @observable
  bool doSingleScan;

  @computed
  bool get isSilentPaymentsScan => wallet.type == WalletType.bitcoin;

  @computed
  bool get isMwebScan => wallet.type == WalletType.litecoin;

  Future<bool> get isBitcoinMempoolAPIEnabled async =>
      wallet.type == WalletType.bitcoin && await bitcoin!.checkIfMempoolAPIIsEnabled(wallet);

  @action
  Future<void> toggleSilentPaymentsScanning(BuildContext context, int height) async {
    return _silentPaymentsScanningViewModel.toggleSilentPaymentsScanning(context, height);
  }

  @action
  Future<void> rescanCurrentWallet({
    required int restoreHeight,
    String? address,
    BuildContext? context,
  }) async {
    state = RescanWalletState.rescaning;
    if (wallet.type != WalletType.bitcoin) {
      wallet.rescan(height: restoreHeight);
      wallet.transactionHistory.clear();
    }
    state = RescanWalletState.none;
  }
}
