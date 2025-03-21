import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:http/http.dart' as http;
class BackgroundSync {
  Future<void> sync() async {
    printV("Background sync started");
    await _checkNetwork();
    await _syncMonero();
    printV("Background sync completed");
  }

  Future<void> _checkNetwork() async {
    final urls = [
      "https://connectivitycheck.gstatic.com",
      "https://static.mrcyjanek.net",
      "https://getmonero.org",
      "https://github.com",
      "https://1.1.1.1/",
    ];
    for (final url in urls) {
      try {
        final response = await http.get(Uri.parse(url));
        printV("Network connection successful (${response.statusCode}) to $url");
      } catch (e) {
        printV("Error checking network: $url: $e");
      }
    }
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
      int syncedTicks = 0;
      final keyService = getIt.get<KeyService>();
      
      inner:
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        final syncStatus = wallet.syncStatus;
        final progress = syncStatus.progress();
        if (syncStatus is NotConnectedSyncStatus) {
          printV("${wallet.name} NOT CONNECTED");
          final node = settingsStore.getCurrentNode(wallet.type);
          await wallet.connectToNode(node: node);
          await wallet.startBackgroundSync();
          printV("STARTED SYNC");
          continue inner;
        }

        if (progress > 0.999 || syncStatus is SyncedSyncStatus) {
          syncedTicks++;
          if (syncedTicks > 5) {
            syncedTicks = 0;
            printV("WALLET $i SYNCED");
            try {
              await wallet.stopBackgroundSync((await keyService.getWalletPassword(walletName: wallet.name)));
            } catch (e) {
              printV("error stopping sync: $e");
            }
            break inner;
          }
        } else {
          syncedTicks = 0;
        }

        if (syncStatus is SyncingSyncStatus) {
          final blocksLeft = syncStatus.blocksLeft;
          printV("$blocksLeft Blocks Left");
        } else if (syncStatus is SyncedSyncStatus) {
          printV("Synced");
        } else if (syncStatus is SyncedTipSyncStatus) {
          printV("Scanned Tip: ${syncStatus.tip}");
        } else if (syncStatus is NotConnectedSyncStatus) {
          printV("Still Not Connected");
        } else if (syncStatus is AttemptingSyncStatus) {
          printV("Attempting Sync");
        } else if (syncStatus is StartingScanSyncStatus) {
          printV("Starting Scan");
        } else if (syncStatus is SyncronizingSyncStatus) {
          printV("Syncronizing");
        } else if (syncStatus is FailedSyncStatus) {
          printV("Failed Sync");
        } else if (syncStatus is ConnectingSyncStatus) {
          printV("Connecting");
        } else {
          printV("Unknown Sync Status ${syncStatus.runtimeType}");
        }
      }
      await wallet.stopBackgroundSync(await keyService.getWalletPassword(walletName: wallet.name));
      await wallet.close(shouldCleanup: true);
    }
  }
}