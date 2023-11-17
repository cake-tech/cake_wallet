import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zano/api/wallet.dart' as zano_wallet;
import 'package:cw_zano/api/wallet_manager.dart' as zano_wallet_manager;
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = ExceptionHandler.onError;

    /// A callback that is invoked when an unhandled error occurs in the root
    /// isolate.
    PlatformDispatcher.instance.onError = (error, stack) {
      ExceptionHandler.onError(
          FlutterErrorDetails(exception: error, stack: stack));

      return true;
    };
    await setup();
    runApp(App());
  }, (error, stackTrace) async {
    ExceptionHandler.onError(
        FlutterErrorDetails(exception: error, stack: stackTrace));
  });
}

final getIt = GetIt.instance;

Future<void> setup() async {
  getIt.registerFactory<KeyService>(
      () => KeyService(getIt.get<FlutterSecureStorage>()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeWidget());
  }
}

class _HomeWidgetState extends State<HomeWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: connect(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return Center(child: Text("connected"));
        },
      ),
    );
  }
  
  static const name = "leo1";

  Future<bool> connect() async {
        calls.getVersion();
    final setupNode = await zano_wallet.setupNode(
        address: "195.201.107.230:33336",
        login: "",
        password: "",
        useSSL: false,
        isLightWallet: false);
    final path = await pathForWallet(name: name, type: WalletType.zano);
    final credentials = ZanoNewWalletCredentials(name: name);
    final keyService = KeyService(FlutterSecureStorage());
    final password = await keyService.getWalletPassword(walletName: credentials.name);
    debugPrint("path $path password $password");
    final result = await calls.loadWallet(path, password, 0);
    final map = json.decode(result) as Map<String, dynamic>;
    int hWallet = 0;
    if (map["result"] != null) {
      hWallet = (map["result"] as Map<String, dynamic>)["wallet_id"] as int;
      debugPrint("hWallet $hWallet");
    }
    Future.delayed(Duration(seconds: 10));
    await calls.getWalletStatus(hWallet);
    Future.delayed(Duration(seconds: 10));
    await calls.getRecentTxsAndInfo(hWallet: hWallet, offset: 0, count: 30);
    Future.delayed(Duration(seconds: 2));
    calls.closeWallet(hWallet);
    return true;
  }

  Future<bool> _connect() async {
    calls.getVersion();
    final result = await zano_wallet.setupNode(
        address: "195.201.107.230:33336",
        login: "",
        password: "",
        useSSL: false,
        isLightWallet: false);
    //debugPrint("setup node result ${result}");
    //final name = "leo1";
    final path = await pathForWallet(name: name, type: WalletType.zano);
    final credentials = ZanoNewWalletCredentials(name: name);
    final keyService = KeyService(FlutterSecureStorage());
    final password = generateWalletPassword();
    credentials.password = password;
    await keyService.saveWalletPassword(
        password: password, walletName: credentials.name);
    final createResult = await zano_wallet_manager.createWallet(
          language: "", path: path, password: credentials.password!);
    debugPrint("createWallet result $createResult");
    final map = json.decode(createResult) as Map<String, dynamic>;
    int hWallet = -1;
    if (map["result"] != null) {
      hWallet = (map["result"] as Map<String, dynamic>)["wallet_id"] as int;
      debugPrint("hWallet $hWallet");
    }
    //await calls.loadWallet(path, password, 0);
    calls.getConnectivityStatus();
    await calls.store(hWallet);
    calls.getWalletInfo(hWallet);
    calls.getWalletStatus(hWallet);
    return true;
  }
}
