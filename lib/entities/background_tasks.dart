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
const initialNotificationContent = 'On standby - app is in the foreground';
const notificationId = 888;
const notificationChannelId = 'cake_service';
const notificationChannelName = 'CAKE BACKGROUND SERVICE';
const notificationChannelDescription = 'Cake Wallet Background Service';
const DELAY_SECONDS_BEFORE_SYNC_START = 15;

void setNotificationStandby(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  flutterLocalNotificationsPlugin.show(
    notificationId,
    initialNotificationTitle,
    initialNotificationContent,
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

  // we have entered the background, start the sync:
  service.on('setBackground').listen((event) async {
    if (bgSyncStarted) {
      return;
    }
    bgSyncStarted = true;

    await Future.delayed(const Duration(seconds: DELAY_SECONDS_BEFORE_SYNC_START));
    print("STARTING SYNC FROM BG!!");

    try {
      await initializeAppConfigs();
    } catch (_) {
      // these errors still show up in logs which doesn't really make sense to me
    }

    print("initialized app configs");

    final currentWallet = getIt.get<AppStore>().wallet;
    // don't start syncing immediately:
    await currentWallet?.stopSync();

    final walletLoadingService = getIt.get<WalletLoadingService>();
    final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

    bool syncAll = true;
    List<WalletBase?> syncingWallets = [];

    if (syncAll) {
      /// get all Monero wallets of the user and sync them
      final List<WalletListItem> moneroWallets = getIt
          .get<WalletListViewModel>()
          .wallets
          .where((element) => [WalletType.monero, WalletType.wownero].contains(element.type))
          .toList();

      for (int i = 0; i < moneroWallets.length; i++) {
        final wallet =
            await walletLoadingService.load(moneroWallets[i].type, moneroWallets[i].name);
        final node = getIt.get<SettingsStore>().getCurrentNode(moneroWallets[i].type);
        await wallet.connectToNode(node: node);
        await wallet.startSync();
        syncingWallets.add(wallet);
      }

      // get all litecoin wallets and sync them:
      final List<WalletListItem> litecoinWallets = getIt
          .get<WalletListViewModel>()
          .wallets
          .where((element) => element.type == WalletType.litecoin)
          .toList();

      // we only need to sync the first litecoin wallet since they share the same collection of blocks
      if (litecoinWallets.isNotEmpty) {
        var firstWallet = litecoinWallets.first;
        final wallet = await walletLoadingService.load(firstWallet.type, firstWallet.name);
        final node = getIt.get<SettingsStore>().getCurrentNode(firstWallet.type);
        await wallet.connectToNode(node: node);
        await wallet.startSync();
        syncingWallets.add(wallet);
      }
    } else {
      // /// if the user chose to sync only active wallet
      // /// if the current wallet is monero; sync it only
      // if (typeRaw == WalletType.monero.index || typeRaw == WalletType.wownero.index) {
      //   final name = getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);
      //   wallet = await walletLoadingService.load(WalletType.values[typeRaw!], name!);
      //   final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.values[typeRaw]);
      //   await wallet.connectToNode(node: node);
      //   await wallet.startSync();
      //   syncingWallets.add(wallet);
      // }
    }

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      // final wallet = getIt.get<AppStore>().wallet;
      final wallet = syncingWallets.first;
      final syncProgress = ((wallet?.syncStatus.progress() ?? 0) * 100).toStringAsPrecision(5);

      flutterLocalNotificationsPlugin.show(
        notificationId,
        "${wallet.name} ${syncProgress}% Synced",
        'Background sync - ${DateTime.now()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            notificationChannelName,
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    });
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

Future<void> initializeService(FlutterBackgroundService bgService) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    notificationChannelName,
    description: notificationChannelDescription,
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  setNotificationStandby(flutterLocalNotificationsPlugin);

  // notify the service that we are in the foreground:
  bgService.invoke("setForeground");

  try {
    bool isServiceRunning = await bgService.isRunning();
    if (isServiceRunning) {
      print("Service is ALREADY running!");
      return;
    }
  } catch (_) {}

  await bgService.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: initialNotificationTitle,
      initialNotificationContent: initialNotificationContent,
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

  void updateServiceState(bool foreground) {
    if (foreground) {
      bgService.invoke('stopService');
      initializeService(bgService);
    } else {
      bgService.invoke("setBackground");
    }
  }

  void registerBackgroundService() async {
    try {
      bool hasMonero = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.monero);

      bool hasLitecoin = getIt
          .get<WalletListViewModel>()
          .wallets
          .any((element) => element.type == WalletType.litecoin);

      /// if its not android nor ios, or the user has no monero wallets; exit
      if (!DeviceInfo.instance.isMobile || (!hasMonero && !hasLitecoin)) {
        return;
      }

      final settingsStore = getIt.get<SettingsStore>();

      final SyncMode syncMode = settingsStore.currentSyncMode;
      final bool syncAll = settingsStore.currentSyncAll;

      if (syncMode.type == SyncType.disabled || !FeatureFlag.isBackgroundSyncEnabled) {
        bgService.invoke('stopService');
        return;
      }

      bgService.invoke('stopService');

      await initializeService(bgService);
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }
}
