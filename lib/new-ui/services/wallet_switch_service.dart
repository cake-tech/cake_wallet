import "package:cake_wallet/core/wallet_loading_service.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";

class WalletSwitchService {
  WalletSwitchService({required this.walletLoadingService, required this.appStore});

  final WalletLoadingService walletLoadingService;
  final AppStore appStore;

  Future<bool> switchToWallet(WalletInfo walletInfo) async {
    try {
      final wallet = await walletLoadingService.load(walletInfo.type, walletInfo.name);

      if (wallet.name != walletInfo.name || wallet.type != walletInfo.type) {
        printV("wallet switch loaded ${wallet.name} instead of ${walletInfo.name}");
        return false;
      }

      await appStore.changeCurrentWallet(wallet);
      return true;
    } catch (e) {
      printV("wallet switch failed: $e");
      return false;
    }
  }
}
