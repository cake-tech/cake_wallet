import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';

class BackgroundSync {
  Future<void> sync() async {
    printV("Background sync started");
    await _syncMonero();
    printV("Background sync completed");
  }

  Future<void> _syncMonero() async {
    final walletLoadingService = getIt.get<WalletLoadingService>();
    final walletListViewModel = getIt.get<WalletListViewModel>();
    final settingsStore = getIt.get<SettingsStore>();


    final List<WalletListItem> moneroWallets = walletListViewModel.wallets
        .where((element) => !element.isHardware)
        .where((element) => [WalletType.monero].contains(element.type))
        .toList();
    for (int i = 0; i < moneroWallets.length; i++) {
      final wallet = await walletLoadingService.load(moneroWallets[i].type, moneroWallets[i].name);
      await wallet.startBackgroundSync();
      await wallet.connectToNode(node: settingsStore.getCurrentNode(wallet.type));
      printV("Background sync started for ${wallet.name}");
      inner:
      while (true) {
        final progress = wallet.syncStatus.progress();
        printV("Background sync status: $progress (${wallet.syncStatus.toString()})");
        await Future.delayed(const Duration(seconds: 1));
        if (progress == 1) {
          break inner;
        }
      }
      final keyService = getIt.get<KeyService>();
      await wallet.stopBackgroundSync(await keyService.getWalletPassword(walletName: wallet.name));
      await wallet.close(shouldCleanup: true);
    }
  }
}