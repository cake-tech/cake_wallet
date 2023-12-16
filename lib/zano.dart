import 'dart:async';
import 'dart:convert';

import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/utils/exception_handler.dart';
import 'package:cake_wallet/zano_connected_widget.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_zano/api/model/balance.dart';
import 'package:cw_zano/api/model/create_wallet_result.dart';
import 'package:cw_zano/api/wallet.dart' as zano_wallet;
import 'package:cw_zano/api/wallet_manager.dart' as zano_wallet_manager;
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = ExceptionHandler.onError;

    /// A callback that is invoked when an unhandled error occurs in the root
    /// isolate.
    PlatformDispatcher.instance.onError = (error, stack) {
      ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stack));

      return true;
    };
    await setup();
    runApp(App());
  }, (error, stackTrace) async {
    ExceptionHandler.onError(FlutterErrorDetails(exception: error, stack: stackTrace));
  });
}

final getIt = GetIt.instance;

Future<void> setup() async {
  getIt.registerFactory<KeyService>(() => KeyService(getIt.get<FlutterSecureStorage>()));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

// class HomeWidget extends StatefulWidget {
//   const HomeWidget({super.key});

//   @override
//   State<HomeWidget> createState() => _HomeWidgetState();
// }

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DisconnectedWidget(), //HomeWidget(),
      routes: {
        ConnectedWidget.route: (context) {
          final address = ModalRoute.of(context)!.settings.arguments! as String;
          return ConnectedWidget(address: address);
        },
        DisconnectedWidget.route: (context) => DisconnectedWidget(),
      },
    );
  }
}

int hWallet = 0;
CreateWalletResult? lwr;
List<Balance> balances = [];
String seed = '', version = '';
final assetIds = <String, String>{};
const walletWrongId = 'WALLET_WRONG_ID';
const walletName = 'walletName';

Future<void> init() async {
  version = calls.getVersion();
  final setupNode = await zano_wallet.setupNode(
      address: '195.201.107.230:33336',
      login: '',
      password: '',
      useSSL: false,
      isLightWallet: false);
  if (!setupNode) {
    debugPrint('error setting up node!');
  }
}

Future<String?> create(String name) async {
  debugPrint('create $name');
  await init();
  final path = await pathForWallet(name: name, type: WalletType.zano);
  final credentials = ZanoNewWalletCredentials(name: name);
  final keyService = KeyService(FlutterSecureStorage());
  final password = generateWalletPassword();
  credentials.password = password;
  await keyService.saveWalletPassword(password: password, walletName: credentials.name);
  debugPrint('path $path password $password');
  final result = calls.createWallet(path: path, password: password, language: '');
  debugPrint('create result $result');
  return _parseResult(result);
}

Future<String?> connect(String name) async {
  debugPrint('connect');
  await init();
  final path = await pathForWallet(name: name, type: WalletType.zano);
  final credentials = ZanoNewWalletCredentials(name: name);
  final keyService = KeyService(FlutterSecureStorage());
  final password = await keyService.getWalletPassword(walletName: credentials.name);
  debugPrint('path $path password $password');
  final result = await calls.loadWallet(path, password, 0);
  return _parseResult(result);
}

Future<String?> restore(String name, String seed) async {
  debugPrint("restore");
  await init();
  final path = await pathForWallet(name: name, type: WalletType.zano);
  final credentials = ZanoNewWalletCredentials(name: name);
  final keyService = KeyService(FlutterSecureStorage());
  final password = generateWalletPassword();
  credentials.password = password;
  await keyService.saveWalletPassword(password: password, walletName: credentials.name);
  debugPrint('path $path password $password');
  var result = calls.restoreWalletFromSeed(path, password, seed);
  debugPrint('restore result $result');
  //result = await calls.loadWallet(path, password, 0);
  return _parseResult(result);
}

String? _parseResult(String result) {
  final map = json.decode(result) as Map<String, dynamic>;
  if (map['result'] != null) {
    lwr = CreateWalletResult.fromJson(map['result'] as Map<String, dynamic>);
    balances = lwr!.wi.balances;
    hWallet = lwr!.walletId;
    assetIds.clear();
    for (final balance in lwr!.wi.balances) {
      assetIds[balance.assetInfo.assetId] = balance.assetInfo.ticker;
    }
    return lwr!.wi.address;
  }
  return null;
}

void close() {
  calls.closeWallet(hWallet);
}

class DisconnectedWidget extends StatefulWidget {
  const DisconnectedWidget({super.key});
  static const route = 'disconnected';

  @override
  State<DisconnectedWidget> createState() => _DisconnectedWidgetState();
}

class _DisconnectedWidgetState extends State<DisconnectedWidget> {
  late final TextEditingController _name = TextEditingController(text: "wallet");
  late final TextEditingController _seed = TextEditingController(
      text:
          "palm annoy brush task almost through here sent doll guilty smart horse mere canvas flirt advice fruit known shower happiness steel autumn beautiful approach anymore canvas");
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    () async {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(walletName);
      if (value != null && value.isNotEmpty) _name.text = value;
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Disconnected')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Stack(
            children: [
              Opacity(
                opacity: _loading ? 0.5 : 1,
                child: Column(
                  children: [
                    TextField(
                        controller: _name, decoration: InputDecoration(labelText: 'Wallet name')),
                    TextButton(
                        child: Text('Connect and Open Wallet'),
                        onPressed: () async {
                          //setState(() => _loading = true);
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.setString(walletName, _name.text);
                          final result = await connect(_name.text);
                          //setState(() => _loading = false);
                          if (result != null) {
                            debugPrint("navigated to connected");
                            Navigator.of(context).pushReplacementNamed(
                              ConnectedWidget.route,
                              arguments: result,
                            );
                          } else {
                            debugPrint('connect no result');
                          }
                        }),
                    SizedBox(
                      height: 16,
                    ),
                    TextButton(
                        child: Text('Create and Open Wallet'),
                        onPressed: () async {
                          //setState(() => _loading = true);
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.setString(walletName, _name.text);
                          final result = await create(_name.text);
                          //setState(() => _loading = false);
                          if (result != null) {
                            debugPrint("navigating to connected");
                            Navigator.of(context).pushReplacementNamed(
                              ConnectedWidget.route,
                              arguments: result,
                            );
                          } else {
                            debugPrint('create no result');
                          }
                        }),
                    SizedBox(
                      height: 16,
                    ),
                    TextField(
                        controller: _seed, decoration: InputDecoration(labelText: 'Wallet seed')),
                    TextButton(
                        child: Text('Restore from seed'),
                        onPressed: () async {
                          final preferences = await SharedPreferences.getInstance();
                          await preferences.setString(walletName, _name.text);
                          final result = await restore(_name.text, _seed.text);
                          if (result != null) {
                            Navigator.of(context).pushReplacementNamed(
                              ConnectedWidget.route,
                              arguments: result,
                            );
                          } else {
                            debugPrint('restore no result');
                          }
                        }),
                    SizedBox(
                      height: 16,
                    ),
                    TextButton(child: Text('Close Wallet'), onPressed: close),
                  ],
                ),
              ),
              if (_loading) Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }
}
