import 'package:cake_wallet/bitcoin/bitcoin.dart';
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/wownero/wownero.dart";
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import "package:polyseed/polyseed.dart";

part 'rescan_view_model.g.dart';

class RescanViewModel = RescanViewModelBase with _$RescanViewModel;

enum RescanWalletState { rescaning, none }

abstract class RescanViewModelBase with Store {
  RescanViewModelBase(this.wallet)
      : state = RescanWalletState.none,
        isButtonEnabled = false,
        doSingleScan = false;

  final WalletBase wallet;

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

  int? get initialRestoreHeight {
    final supportsPolyseed = wallet.type == WalletType.monero || wallet.type == WalletType.wownero;

    if (!supportsPolyseed || !wallet.isSoftwareWallet) {
      return null;
    }

    final seed = wallet.seed;

    if (seed == null || !Polyseed.isValidSeed(seed)) {
      return null;
    }

    try {
      final language = PolyseedLang.getByPhrase(seed);
      final coin = wallet.type == WalletType.monero
          ? PolyseedCoin.POLYSEED_MONERO
          : PolyseedCoin.POLYSEED_WOWNERO;
      final birthday = DateTime.fromMillisecondsSinceEpoch(
        Polyseed.decode(seed, language, coin).birthday * 1000,
      );
      final restoreHeight = wallet.type == WalletType.monero
          ? monero!.getHeightByDate(date: birthday)
          : wownero!.getHeightByDate(date: birthday);

      return restoreHeight > 0 ? restoreHeight : null;
    } catch (_) {
      return null;
    }
  }

  @action
  Future<void> rescanCurrentWallet({required int restoreHeight}) async {
    state = RescanWalletState.rescaning;
    if (wallet.type != WalletType.bitcoin) {
      wallet.rescan(height: restoreHeight);
      wallet.transactionHistory.clear();
    } else {
      bitcoin!.rescan(wallet, height: restoreHeight, doSingleScan: doSingleScan);
    }
    state = RescanWalletState.none;
  }
}
