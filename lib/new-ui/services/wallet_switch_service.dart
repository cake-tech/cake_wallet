import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/wallet_info.dart";

class WalletSwitchService {
  WalletSwitchService({
    required WalletLoadingService walletLoadingService,
    required AppStore appStore,
  }) : _walletLoadingService = walletLoadingService,
       _appStore = appStore;

  final AppStore _appStore;
  final WalletLoadingService _walletLoadingService;

  Future<void> switchToWallet(WalletInfo walletInfo) async {
    final wallet = await _walletLoadingService.load(walletInfo.type, walletInfo.name);

    await _appStore.changeCurrentWallet(wallet);
  }
}
