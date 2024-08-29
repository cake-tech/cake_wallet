import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
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
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/di.dart';
import 'package:http/http.dart' as http;

const moneroSyncTaskKey = "com.fotolockr.cakewallet.monero_sync_task";
const mwebSyncTaskKey = "com.fotolockr.cakewallet.mweb_sync_task";

@pragma('vm:entry-point')
void callbackDispatcher() {
  // Workmanager().executeTask((task, inputData) async {
  //   try {
  //     switch (task) {
  //       case mwebSyncTaskKey:

  //         /// The work manager runs on a separate isolate from the main flutter isolate.
  //         /// thus we initialize app configs first; hive, getIt, etc...
  //         await initializeAppConfigs();

  //         final List<WalletListItem> ltcWallets = getIt
  //             .get<WalletListViewModel>()
  //             .wallets
  //             .where((element) => [WalletType.litecoin].contains(element.type))
  //             .toList();

  //         if (ltcWallets.isEmpty) {
  //           return Future.error("No ltc wallets found");
  //         }

  //         final walletLoadingService = getIt.get<WalletLoadingService>();

  //         var wallet =
  //             await walletLoadingService.load(ltcWallets.first.type, ltcWallets.first.name);

  //         print("STARTING SYNC FROM BG!!");

  //         final url = Uri.parse("https://webhook.site/a81e49d8-f5bd-4e57-8b1d-5d2c80c43f2a");
  //         final response = await http.get(url);

  //         if (response.statusCode == 200) {
  //           print("Background task starting: ${response.body}");
  //         } else {
  //           print("Failed to post webhook.site");
  //         }

  //         // await wallet.startSync();

  //         // RpcClient _stub = bitcoin!.getMwebStub();

  //         double syncStatus = 0.0;

  //         Timer? _syncTimer;

  //         // dynamic _stub = await bitcoin!.getMwebStub(wallet);

  //         _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
  //           // if (syncStatus is FailedSyncStatus) return;
  //           // TODO: use the proxy layer:
  //           // final height = await (wallet as ElectrumWallet).electrumClient.getCurrentBlockChainTip() ?? 0;
  //           final height = 2726590;
  //           // final height = 0;
  //           dynamic resp = await bitcoin!.getStatusRequest(wallet);
  //           int blockHeaderHeight = resp.blockHeaderHeight as int;
  //           int mwebHeaderHeight = resp.mwebHeaderHeight as int;
  //           int mwebUtxosHeight = resp.mwebUtxosHeight as int;

  //           print("blockHeaderHeight: $blockHeaderHeight");
  //           print("mwebHeaderHeight: $mwebHeaderHeight");
  //           print("mwebUtxosHeight: $mwebUtxosHeight");

  //           if (blockHeaderHeight < height) {
  //             syncStatus = blockHeaderHeight / height;
  //           } else if (mwebHeaderHeight < height) {
  //             syncStatus = mwebHeaderHeight / height;
  //           } else if (mwebUtxosHeight < height) {
  //             syncStatus = 0.999;
  //           } else {
  //             syncStatus = 1;
  //           }
  //           print("Sync status ${syncStatus}");
  //         });

  //         for (int i = 0;; i++) {
  //           await Future<void>.delayed(const Duration(seconds: 1));
  //           if (syncStatus == 1) {
  //             print("sync done!");
  //             break;
  //           }
  //           if (i > 600) {
  //             return Future.error("Synchronization Timed out");
  //           }
  //         }
  //         _syncTimer?.cancel();

  //         break;

  //       case moneroSyncTaskKey:

  //         /// The work manager runs on a separate isolate from the main flutter isolate.
  //         /// thus we initialize app configs first; hive, getIt, etc...
  //         await initializeAppConfigs();

  //         final walletLoadingService = getIt.get<WalletLoadingService>();

  //         final typeRaw = getIt.get<SharedPreferences>().getInt(PreferencesKey.currentWalletType);

  //         WalletBase? wallet;

  //         if (inputData!['sync_all'] as bool) {
  //           /// get all Monero wallets of the user and sync them
  //           final List<WalletListItem> moneroWallets = getIt
  //               .get<WalletListViewModel>()
  //               .wallets
  //               .where((element) => [WalletType.monero, WalletType.wownero].contains(element.type))
  //               .toList();

  //           for (int i = 0; i < moneroWallets.length; i++) {
  //             wallet =
  //                 await walletLoadingService.load(moneroWallets[i].type, moneroWallets[i].name);
  //             final node = getIt.get<SettingsStore>().getCurrentNode(moneroWallets[i].type);
  //             await wallet.connectToNode(node: node);
  //             await wallet.startSync();
  //           }
  //         } else {
  //           /// if the user chose to sync only active wallet
  //           /// if the current wallet is monero; sync it only
  //           if (typeRaw == WalletType.monero.index || typeRaw == WalletType.wownero.index) {
  //             final name =
  //                 getIt.get<SharedPreferences>().getString(PreferencesKey.currentWalletName);

  //             wallet = await walletLoadingService.load(WalletType.values[typeRaw!], name!);
  //             final node = getIt.get<SettingsStore>().getCurrentNode(WalletType.values[typeRaw]);

  //             await wallet.connectToNode(node: node);
  //             await wallet.startSync();
  //           }
  //         }

  //         if (wallet?.syncStatus.progress() == null) {
  //           return Future.error("No Monero/Wownero wallet found");
  //         }

  //         for (int i = 0;; i++) {
  //           await Future<void>.delayed(const Duration(seconds: 1));
  //           if (wallet?.syncStatus.progress() == 1.0) {
  //             break;
  //           }
  //           if (i > 600) {
  //             return Future.error("Synchronization Timed out");
  //           }
  //         }
  //         break;
  //     }

  //     return Future.value(true);
  //   } catch (error, stackTrace) {
  //     print(error);
  //     print(stackTrace);
  //     return Future.error(error);
  //   }
  // });
}

@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  print("BACKGROUND SERVICE STARTED!");

  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

// this will be used as notification channel id
  const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
  const notificationId = 888;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // // bring to foreground
  // Timer.periodic(const Duration(seconds: 1), (timer) async {
  //   if (service is AndroidServiceInstance) {
  //     if (await service.isForegroundService()) {
  //       flutterLocalNotificationsPlugin.show(
  //         notificationId,
  //         'COOL SERVICE',
  //         'Awesome ${DateTime.now()}',
  //         const NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             notificationChannelId,
  //             'MY FOREGROUND SERVICE',
  //             icon: 'ic_bg_service_small',
  //             ongoing: true,
  //           ),
  //         ),
  //       );
  //     } else {
  //       flutterLocalNotificationsPlugin.show(
  //         notificationId,
  //         'BACKGROUND SERVICE?',
  //         'Awesome ${DateTime.now()}',
  //         const NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             notificationChannelId,
  //             'MY FOREGROUND SERVICE',
  //             icon: 'ic_bg_service_small',
  //             ongoing: true,
  //           ),
  //         ),
  //       );
  //     }
  //   }
  // });

  // /// The work manager runs on a separate isolate from the main flutter isolate.
  // /// thus we initialize app configs first; hive, getIt, etc...
  // await initializeAppConfigs();

  service.on('status').listen((event) async {
    print(event);
  });

  bool bgSyncStarted = false;

  service.on('startBgSync').listen((event) async {
    if (bgSyncStarted) {
      return;
    }
    bgSyncStarted = true;
    print("STARTING SYNC FROM BG!!");

    await initializeAppConfigs();

    print("initialized app configs");

    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      final wallet = getIt.get<AppStore>().wallet;
      final syncProgress = wallet?.syncStatus.progress();

      flutterLocalNotificationsPlugin.show(
        notificationId,
        "${syncProgress}",
        'Awesome ${DateTime.now()}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            notificationChannelId,
            'MY FOREGROUND SERVICE',
            icon: 'ic_bg_service_small',
            ongoing: true,
          ),
        ),
      );
    });
  });

  // final List<WalletListItem> ltcWallets = getIt
  //     .get<WalletListViewModel>()
  //     .wallets
  //     .where((element) => [WalletType.litecoin].contains(element.type))
  //     .toList();

  // if (ltcWallets.isEmpty) {
  //   return Future.error("No ltc wallets found");
  // }

  // final walletLoadingService = getIt.get<WalletLoadingService>();

  // var wallet = await walletLoadingService.load(ltcWallets.first.type, ltcWallets.first.name);

  // var wallet = getIt.get<AppStore>().wallet;

  // if (wallet?.type != WalletType.litecoin) {
  //   return;
  // }

  // print("STARTING SYNC FROM BG!!");

  // final url = Uri.parse("https://webhook.site/a81e49d8-f5bd-4e57-8b1d-5d2c80c43f2a");
  // final response = await http.get(url);

  // if (response.statusCode == 200) {
  //   print("Background task starting: ${response.body}");
  // } else {
  //   print("Failed to post webhook.site");
  // }

  // Timer.periodic(Duration(milliseconds: 5000), (timer) async {
  //   print(wallet!.syncStatus);
  // });

  // await wallet.startSync();

  // RpcClient _stub = bitcoin!.getMwebStub();

  // double syncStatus = 0.0;

  // Timer? _syncTimer;

  // dynamic _stub = await bitcoin!.getMwebStub(wallet);

  // _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
  //   // if (syncStatus is FailedSyncStatus) return;
  //   // TODO: use the proxy layer:
  //   // final height = await (wallet as ElectrumWallet).electrumClient.getCurrentBlockChainTip() ?? 0;
  //   final height = 2726590;
  //   // final height = 0;
  //   dynamic resp = await bitcoin!.getStatusRequest(wallet);
  //   int blockHeaderHeight = resp.blockHeaderHeight as int;
  //   int mwebHeaderHeight = resp.mwebHeaderHeight as int;
  //   int mwebUtxosHeight = resp.mwebUtxosHeight as int;

  //   print("blockHeaderHeight: $blockHeaderHeight");
  //   print("mwebHeaderHeight: $mwebHeaderHeight");
  //   print("mwebUtxosHeight: $mwebUtxosHeight");

  //   if (blockHeaderHeight < height) {
  //     syncStatus = blockHeaderHeight / height;
  //   } else if (mwebHeaderHeight < height) {
  //     syncStatus = mwebHeaderHeight / height;
  //   } else if (mwebUtxosHeight < height) {
  //     syncStatus = 0.999;
  //   } else {
  //     syncStatus = 1;
  //   }
  //   print("Sync status ${syncStatus}");

  //   flutterLocalNotificationsPlugin.show(
  //     notificationId,
  //     '${syncStatus}',
  //     'Awesome ${DateTime.now()}',
  //     const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         notificationChannelId,
  //         'MY FOREGROUND SERVICE',
  //         icon: 'ic_bg_service_small',
  //         ongoing: true,
  //       ),
  //     ),
  //   );
  // });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  return true;
}

Future<void> initializeService(FlutterBackgroundService bgService) async {
  // final service = FlutterBackgroundService();

  // await service.configure(
  //   iosConfiguration: IosConfiguration(
  //     autoStart: true,
  //     onForeground: onStart,
  //     onBackground: onIosBackground,
  //   ),
  //   androidConfiguration: AndroidConfiguration(
  //     autoStart: true,
  //     onStart: onStart,
  //     isForegroundMode: false,
  //     autoStartOnBoot: true,
  //   ),
  // );

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
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

  await bgService.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );

  var wallet = getIt.get<AppStore>().wallet;

  Timer.periodic(const Duration(milliseconds: 1000), (timer) {
    if (wallet?.syncStatus.toString() == "stopped") {
      bgService.invoke("startBgSync");
    }
    // bgService.invoke("status", {"status": wallet?.syncStatus.toString()});
  });
}

class BackgroundTasks {
  FlutterBackgroundService bgService = FlutterBackgroundService();

  void registerSyncTask({bool changeExisting = false}) async {
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

      await initializeService(bgService);

      //     await service.configure(
      // androidConfiguration: AndroidConfiguration(
      //   // this will be executed when app is in foreground or background in separated isolate
      //   onStart: onStart,

      //   // auto start service
      //   autoStart: true,
      //   isForegroundMode: true,

      //   notificationChannelId: notificationChannelId, // this must match with notification channel you created above.
      //   initialNotificationTitle: 'AWESOME SERVICE',
      //   initialNotificationContent: 'Initializing',
      //   foregroundServiceNotificationId: notificationId,
      // );

      // await Workmanager().initialize(
      //   callbackDispatcher,
      //   isInDebugMode: true,
      // );

      // final inputData = <String, dynamic>{"sync_all": syncAll};
      // final constraints = Constraints(
      //   networkType:
      //       syncMode.type == SyncType.unobtrusive ? NetworkType.unmetered : NetworkType.connected,
      //   requiresBatteryNotLow: syncMode.type == SyncType.unobtrusive,
      //   requiresCharging: syncMode.type == SyncType.unobtrusive,
      //   requiresDeviceIdle: syncMode.type == SyncType.unobtrusive,
      // );

      // if (Platform.isIOS && syncMode.type == SyncType.unobtrusive) {
      //   // await Workmanager().registerOneOffTask(
      //   //   moneroSyncTaskKey,
      //   //   moneroSyncTaskKey,
      //   //   initialDelay: syncMode.frequency,
      //   //   existingWorkPolicy: ExistingWorkPolicy.replace,
      //   //   inputData: inputData,
      //   //   constraints: constraints,
      //   // );
      //   await Workmanager().registerOneOffTask(
      //     mwebSyncTaskKey,
      //     mwebSyncTaskKey,
      //     initialDelay: Duration(seconds: 30),
      //     existingWorkPolicy: ExistingWorkPolicy.replace,
      //     inputData: inputData,
      //     constraints: constraints,
      //   );
      //   return;
      // }

      // await Workmanager().registerPeriodicTask(
      //   moneroSyncTaskKey,
      //   moneroSyncTaskKey,
      //   initialDelay: syncMode.frequency,
      //   frequency: syncMode.frequency,
      //   existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
      //   inputData: inputData,
      //   constraints: constraints,
      // );
      // await Workmanager().registerPeriodicTask(
      //   mwebSyncTaskKey,
      //   mwebSyncTaskKey,
      //   initialDelay: syncMode.frequency,
      //   frequency: syncMode.frequency,
      //   existingWorkPolicy: changeExisting ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
      //   inputData: inputData,
      //   constraints: constraints,
      // );
    } catch (error, stackTrace) {
      print(error);
      print(stackTrace);
    }
  }

  void cancelSyncTask() {
    // try {
    //   Workmanager().cancelByUniqueName(moneroSyncTaskKey);
    // } catch (error, stackTrace) {
    //   print(error);
    //   print(stackTrace);
    // }
    // try {
    //   Workmanager().cancelByUniqueName(mwebSyncTaskKey);
    // } catch (error, stackTrace) {
    //   print(error);
    //   print(stackTrace);
    // }
  }
}
