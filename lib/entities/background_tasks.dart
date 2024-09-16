import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_view_model.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

const moneroSyncTaskKey = "com.fotolockr.cakewallet.monero_sync_task";
const mwebSyncTaskKey = "com.fotolockr.cakewallet.mweb_sync_task";

const initialNotificationTitle = 'Cake Background Sync';
const standbyMessage = 'On standby - app is in the foreground';
const readyMessage = 'Ready to sync - waiting until the app has been in the background for a while';

const notificationId = 888;
const notificationChannelId = 'cake_service';
const notificationChannelName = 'CAKE BACKGROUND SERVICE';
const notificationChannelDescription = 'Cake Wallet Background Service';
const DELAY_SECONDS_BEFORE_SYNC_START = 15;

const spNotificationId = 888;
const spNodeNotificationMessage = "Currently configured Bitcoin node does not support Silent Payments. skipping wallet";


void setNotificationStandby(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  flutterLocalNotificationsPlugin.cancelAll();
  flutterLocalNotificationsPlugin.show(
    notificationId,
    initialNotificationTitle,
    standbyMessage,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        icon: 'ic_bg_service_small',
        ongoing: true,
      ),
    ),
  );
}

void setNotificationReady(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  flutterLocalNotificationsPlugin.cancelAll();
  flutterLocalNotificationsPlugin.show(
    notificationId,
    initialNotificationTitle,
    readyMessage,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        icon: 'ic_bg_service_small',
        ongoing: true,
      ),
    ),
  );
}

void setSpNodeWarningNotification(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  flutterLocalNotificationsPlugin.cancelAll();
  flutterLocalNotificationsPlugin.show(
    notificationId,
    initialNotificationTitle,
    spNodeNotificationMessage,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        notificationChannelId,
        notificationChannelName,
        icon: 'ic_bg_service_small',
        ongoing: true,
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  print("BACKGROUND SERVICE STARTED!");
  bool bgSyncStarted = false;
  Timer? _syncTimer;

  // commented because the behavior appears to be bugged:
  // DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) async {
    print("STOPPING BACKGROUND SERVICE!");
    _syncTimer?.cancel();
    await service.stopSelf();
  });

  service.on('status').listen((event) async {
    print(event);
  });

  service.on('setForeground').listen((event) async {
    bgSyncStarted = false;
    _syncTimer?.cancel();
    setNotificationStandby(flutterLocalNotificationsPlugin);
  });

  service.on('setReady').listen((event) async {
    setNotificationReady(flutterLocalNotificationsPlugin);
  });

  // we have entered the background, start the sync:
  service.on('setBackground').listen((event) async {
    if (bgSyncStarted) {
      return;
    }
    bgSyncStarted = true;

    await Future.delayed(const Duration(seconds: DELAY_SECONDS_BEFORE_SYNC_START));
    print("STARTING SYNC FROM BG!!");

    try {
      await initializeAppConfigs(loadWallet: false);
    } catch (_) {
      // these errors still show up in logs which doesn't really make sense to me
    }

    print("INITIALIZED APP CONFIGS");

    final currentWallet = getIt.get<AppStore>().wallet;
    // don't start syncing immediately:
    await currentWallet?.stopSync();

    final walletLoadingService = getIt.get<WalletLoadingService>();
    final settingsStore = getIt.get<SettingsStore>();
    final walletListViewModel = getIt.get<WalletListViewModel>();
    final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

    bool syncAll = true;
    List<WalletBase?> syncingWallets = [];

    if (syncAll) {
      /// get all Monero wallets of the user and sync them
      final List<WalletListItem> moneroWallets = walletListViewModel.wallets
          .where((element) => [WalletType.monero, WalletType.wownero].contains(element.type))
          .toList();

      for (int i = 0; i < moneroWallets.length; i++) {
        final wallet =
            await walletLoadingService.load(moneroWallets[i].type, moneroWallets[i].name);
        final node = settingsStore.getCurrentNode(moneroWallets[i].type);
        await wallet.connectToNode(node: node);
        await wallet.startSync();
        syncingWallets.add(wallet);
      }

      // get all litecoin wallets and sync them:
      final List<WalletListItem> litecoinWallets = walletListViewModel.wallets
          .where((element) => element.type == WalletType.litecoin)
          .toList();

      // we only need to sync the first litecoin wallet since they share the same collection of blocks
      // if (litecoinWallets.isNotEmpty) {
      //   try {
      //     final firstWallet = litecoinWallets.first;
      //     final wallet = await walletLoadingService.load(firstWallet.type, firstWallet.name);
      //     final node = settingsStore.getCurrentNode(firstWallet.type);
      //     await wallet.connectToNode(node: node);
      //     // calling start sync isn't necessary since it's called after connecting to the node
      //     syncingWallets.add(wallet);
      //   } catch (e) {
      //     // couldn't connect to mwebd (most likely)
      //     print("error syncing litecoin wallet: $e");
      //   }
      // }

      final List<WalletListItem> bitcoinWallets = walletListViewModel.wallets
          .where((element) => element.type == WalletType.bitcoin)
          .toList();

      for (int i = 0; i < bitcoinWallets.length; i++) {
        try {
          final wallet =
              await walletLoadingService.load(bitcoinWallets[i].type, bitcoinWallets[i].name);
          final node = settingsStore.getCurrentNode(bitcoinWallets[i].type);

          // bool nodeSupportsSP = await (wallet as ElectrumWallet).getNodeSupportsSilentPayments();
          // TODO: fix this:
          bool nodeSupportsSP = node.uriRaw.contains("electrs");
          if (!nodeSupportsSP) {
            print("Configured node does not support silent payments, skipping wallet");
            setSpNodeWarningNotification(flutterLocalNotificationsPlugin);
            continue;
          }
          // await wallet.connectToNode(node: node);
          // (wallet as ElectrumWallet).setSilentPaymentsScanning(true);
          (wallet as ElectrumWallet).rescan(height: 1);
          syncingWallets.add(wallet);
        } catch (e) {
          print("error syncing bitcoin wallet: $e");
        }
      }
    } else {
      /// if the user chose to sync only active wallet
      /// if the current wallet is monero; sync it only
      if (typeRaw == WalletType.monero.index || typeRaw == WalletType.wownero.index) {
        final name = getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);
        final wallet = await walletLoadingService.load(WalletType.values[typeRaw!], name!);
        final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.values[typeRaw]);
        await wallet.connectToNode(node: node);
        await wallet.startSync();
        syncingWallets.add(wallet);
      }
    }

    print("STARTING SYNC TIMER");
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (syncingWallets.isEmpty) {
        return;
      }

      for (int i = 0; i < syncingWallets.length; i++) {
        final wallet = syncingWallets[i];
        final syncProgress = ((wallet!.syncStatus.progress()) * 100).toStringAsPrecision(5);

        String prefix = walletTypeToCryptoCurrency(wallet.type).title;
        String title = "$prefix - ${wallet.name}";
        late String content;
        try {
          final blocksLeft = (wallet.syncStatus as SyncingSyncStatus).blocksLeft;
          content = "${blocksLeft} Blocks Left";
        } catch (e) {
          print(e);
          content = "${syncProgress}% Synced";
        }
        content += " - ${DateTime.now()}";

        flutterLocalNotificationsPlugin.show(
          notificationId + i,
          title,
          content,
          NotificationDetails(
            android: AndroidNotificationDetails(
              "${notificationChannelId}_$i",
              "${notificationChannelName}_$i",
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    });
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

Future<void> initializeService(FlutterBackgroundService bgService, bool useNotifications) async {
  if (useNotifications) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('ic_bg_service_small'),
        ),
      );
    }

    for (int i = 0; i < 10; i++) {
      AndroidNotificationChannel channel = AndroidNotificationChannel(
        "${notificationChannelId}_$i",
        "${notificationChannelName}_$i",
        description: notificationChannelDescription,
        importance: Importance.low,
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    setNotificationStandby(flutterLocalNotificationsPlugin);
  }

  // notify the service that we are in the foreground:
  bgService.invoke("setForeground");

  try {
    bool isServiceRunning = await bgService.isRunning();
    if (isServiceRunning) {
      print("Service is ALREADY running!");
      return;
    }
  } catch (_) {}

  print("INITIALIZING SERVICE");

  await bgService.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: initialNotificationTitle,
      initialNotificationContent: standbyMessage,
      foregroundServiceNotificationId: notificationId,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

class BackgroundTasks {
  FlutterBackgroundService bgService = FlutterBackgroundService();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void serviceBackground() {
    bgService.invoke("setBackground");
  }

  Future<void> serviceForeground() async {
    final settingsStore = getIt.get<SettingsStore>();
    bool showNotifications = settingsStore.showSyncNotification;
    bgService.invoke('stopService');
    await Future.delayed(const Duration(seconds: 2));
    initializeService(bgService, showNotifications);
  }

  void serviceReady() {
    final settingsStore = getIt.get<SettingsStore>();
    bool showNotifications = settingsStore.showSyncNotification;
    if (showNotifications) {
      bgService.invoke('setReady');
    }
  }

  void registerBackgroundService() async {
    print("REGISTER BACKGROUND SERVICE");
    try {
      final settingsStore = getIt.get<SettingsStore>();
      final walletListViewModel = getIt.get<WalletListViewModel>();
      bool hasMonero =
          walletListViewModel.wallets.any((element) => element.type == WalletType.monero);

      bool hasLitecoin =
          walletListViewModel.wallets.any((element) => element.type == WalletType.litecoin);

      bool hasBitcoin =
          walletListViewModel.wallets.any((element) => element.type == WalletType.bitcoin);

      if (!settingsStore.silentPaymentsAlwaysScan) {
        hasBitcoin = false;
      }
      if (!settingsStore.mwebAlwaysScan) {
        hasLitecoin = false;
      }

      /// if its not android nor ios, or the user has no monero wallets; exit
      if (!DeviceInfo.instance.isMobile || (!hasMonero && !hasLitecoin && !hasBitcoin)) {
        return;
      }

      final SyncMode syncMode = settingsStore.currentSyncMode;
      final bool syncAll = settingsStore.currentSyncAll;

      if (syncMode.type == SyncType.disabled || !FeatureFlag.isBackgroundSyncEnabled) {
        bgService.invoke('stopService');
        return;
      }

      if (settingsStore.showSyncNotification) {
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      bgService.invoke('stopService');

      await initializeService(bgService, settingsStore.showSyncNotification);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }
}
