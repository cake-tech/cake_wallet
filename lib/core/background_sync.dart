import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/evm/evm.dart';

class BackgroundSync {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> _initializeNotifications() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return await _notificationsPlugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              ) ??
          false;
    } else if (Platform.isAndroid) {
      return await _notificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    return false;
  }

  Future<void> showNotification(String title, String content) async {
    await _initializeNotifications();
    final hasPermission = await requestPermissions();

    if (!hasPermission) {
      printV('Notification permissions not granted');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'transactions',
      'Transactions',
      channelDescription: 'Channel for notifications about transactions',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.hashCode,
      title,
      content,
      notificationDetails,
    );
  }

  Future<void> sync() async {
    final settingsStore = getIt.get<SettingsStore>();
    if (settingsStore.currentBuiltinTor) {
      printV("Starting Tor");
      await ensureTorStarted(context: null);
    }
    printV("Background sync started");
    await _syncWallets();
    printV("Background sync completed");
  }

  Future<void> _syncWallets() async {
    final walletLoadingService = getIt.get<WalletLoadingService>();
    final walletListViewModel = getIt.get<WalletListViewModel>();
    final settingsStore = getIt.get<SettingsStore>();

    final List<WalletListItem> moneroWallets = walletListViewModel.wallets
        .where((element) => !element.isHardware)
        .where((element) => ![WalletType.haven, WalletType.decred].contains(element.type))
        .toList();
    for (int i = 0; i < moneroWallets.length; i++) {
      final wallet = await walletLoadingService.load(moneroWallets[i].type, moneroWallets[i].name,
          isBackground: true);
      int syncedTicks = 0;
      final keyService = getIt.get<KeyService>();

      int stuckTicks = 0;

      inner:
      while (true) {
        await Future.delayed(const Duration(seconds: 1));
        final syncStatus = wallet.syncStatus;
        final progress = syncStatus.progress();
        if (syncStatus is ConnectedSyncStatus ||
            syncStatus is AttemptingSyncStatus ||
            syncStatus is NotConnectedSyncStatus) {
          stuckTicks++;
          if (stuckTicks > 30) {
            printV("${wallet.name} STUCK SYNCING");
            break inner;
          }
        } else {
          stuckTicks = 0;
        }
        if (syncStatus is NotConnectedSyncStatus) {
          printV("${wallet.name} NOT CONNECTED");

          int? chainId;
          if (isEVMCompatibleChain(wallet.type)) {
            chainId = evm!.getSelectedChainId(wallet);
          }

          final node = settingsStore.getCurrentNode(wallet.type, chainId: chainId);
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
              await wallet.stopBackgroundSync(
                  (await keyService.getWalletPassword(walletName: wallet.name)));
            } catch (e) {
              printV("error stopping sync: $e");
            }
            break inner;
          }
        } else {
          syncedTicks = 0;
        }
        if (FeatureFlag.hasDevOptions) {
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
      }
      final txs = wallet.transactionHistory;
      final sortedTxs = txs.transactions.values.toList()..sort((a, b) => a.date.compareTo(b.date));
      final sharedPreferences = await SharedPreferences.getInstance();
      for (final tx in sortedTxs) {
        final lastTriggerString =
            sharedPreferences.getString(PreferencesKey.backgroundSyncLastTrigger(wallet.name));
        final lastTriggerDate =
            lastTriggerString != null ? DateTime.parse(lastTriggerString) : DateTime.now();
        final keys = sharedPreferences.getKeys();
        if (tx.date.isBefore(lastTriggerDate)) {
          printV(
              "w: ${wallet.name}, tx: ${tx.date} is before $lastTriggerDate (lastTriggerString: $lastTriggerString) (k: ${keys.length})");
          continue;
        }
        await sharedPreferences.setString(PreferencesKey.backgroundSyncLastTrigger(wallet.name),
            tx.date.add(Duration(minutes: 1)).toIso8601String());
        final action = tx.direction == TransactionDirection.incoming ? "Received" : "Sent";
        if (sharedPreferences.getBool(PreferencesKey.backgroundSyncNotificationsEnabled) ?? false) {
          await showNotification(
              "$action ${wallet.currency.fullName} in ${wallet.name}", "${tx.amountFormatted()}");
        }
        printV(
            "${wallet.currency.fullName} in ${wallet.name}: TX: ${tx.date} ${tx.amount} ${tx.direction}");
      }
      wallet.id;
      await wallet.stopBackgroundSync(await keyService.getWalletPassword(walletName: wallet.name));
      await wallet.close(shouldCleanup: true);
    }
  }
}
