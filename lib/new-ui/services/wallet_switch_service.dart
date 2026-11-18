import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/exceptions.dart";
import "package:cw_core/wallet_info.dart";

class WalletSwitchService {
  WalletSwitchService({
    required WalletLoadingService walletLoadingService,
    required AppStore appStore,
  })  : _walletLoadingService = walletLoadingService,
        _appStore = appStore;

  final AppStore _appStore;
  final WalletLoadingService _walletLoadingService;

  Future<void> switchToWallet(WalletInfo walletInfo) async {
    final wallet = await _walletLoadingService.load(walletInfo);

    // load() recovers from a corrupted wallet by opening any other wallet it can,
    // so the one it returns may not be the one that was requested.
    if (wallet.name != walletInfo.name || wallet.type != walletInfo.type) {
      throw WalletSwitchException(
        "wallet switch loaded ${wallet.name} instead of ${walletInfo.name}",
      );
    }

    await _appStore.changeCurrentWallet(wallet);
  }
}
