import 'dart:io';
import 'dart:math';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'rescan_view_model.g.dart';

class RescanViewModel = RescanViewModelBase with _$RescanViewModel;

enum RescanWalletState { rescaning, none }

abstract class RescanViewModelBase with Store {
  RescanViewModelBase(this.wallet)
      : state = RescanWalletState.none,
        isButtonEnabled = false,
        doSingleScan = false,
        historicalMode = false,
        workerCount = max(1, Platform.numberOfProcessors ~/ 2);

  final WalletBase wallet;

  @observable
  RescanWalletState state;

  @observable
  bool isButtonEnabled;

  @observable
  bool doSingleScan;

  // Whether a Bitcoin Silent Payments manual rescan should also archive
  // already-spent outputs (slower) or skip them for a faster scan.
  @observable
  bool historicalMode;

  // User-chosen scan worker count (Rescan page slider). Defaults to half the
  // device's cores, floored to 1. Only meaningful (and only unlocked in the
  // UI) once the connected node has negotiated the v2 wire protocol - a
  // legacy-only node stays forced to 1 worker regardless of this value,
  // enforced independently on the wallet side (ElectrumWalletBase.rescan ->
  // _scanWorkerCount), not just here.
  @observable
  int workerCount;

  @computed
  bool get isSilentPaymentsScan => wallet.type == WalletType.bitcoin;

  @computed
  bool get isMwebScan => wallet.type == WalletType.litecoin;

  // Device's own core count - the slider's max.
  int get maxWorkerCount => Platform.numberOfProcessors;

  // Whether the currently-connected node has negotiated the v2 protocol.
  bool get supportsParallelScanning =>
      wallet.type == WalletType.bitcoin && bitcoin!.negotiatedScanProtocolVersion(wallet) >= 2;

  Future<bool> get isBitcoinMempoolAPIEnabled async =>
      wallet.type == WalletType.bitcoin && await bitcoin!.checkIfMempoolAPIIsEnabled(wallet);

  @action
  Future<void> rescanCurrentWallet({required int restoreHeight}) async {
    state = RescanWalletState.rescaning;
    if (wallet.type != WalletType.bitcoin) {
      wallet.rescan(height: restoreHeight);
      wallet.transactionHistory.clear();
    } else {
      bitcoin!.rescan(
        wallet,
        height: restoreHeight,
        doSingleScan: doSingleScan,
        workerCount: workerCount,
        historicalMode: historicalMode,
      );
    }
    state = RescanWalletState.none;
  }
}
