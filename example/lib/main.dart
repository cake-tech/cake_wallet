import 'dart:core';
import 'dart:math';

import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:cw_monero/pending_monero_transaction.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:core' as core;

import 'package:flutter/services.dart';
import 'package:flutter_libmonero/core/key_service.dart';
import 'package:flutter_libmonero/flutter_libmonero.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cw_core/wallet_type.dart';
import 'dart:io';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:flutter_libmonero/core/wallet_creation_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_libmonero/view_model/send/output.dart';

import 'package:cw_monero/api/wallet.dart';

FlutterSecureStorage? storage;
WalletService? walletService;
SharedPreferences? prefs;
KeyService? keysStorage;
MoneroWalletBase? walletBase;
late WalletCreationService _walletCreationService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory appDir = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    appDir = (await getLibraryDirectory());
  }
  await Hive.close();
  Hive.init(appDir.path);

  if (!Hive.isAdapterRegistered(Node.typeId)) {
    Hive.registerAdapter(NodeAdapter());
  }

  if (!Hive.isAdapterRegistered(WalletInfo.typeId)) {
    Hive.registerAdapter(WalletInfoAdapter());
  }

  if (!Hive.isAdapterRegistered(walletTypeTypeId)) {
    Hive.registerAdapter(WalletTypeAdapter());
  }

  if (!Hive.isAdapterRegistered(UnspentCoinsInfo.typeId)) {
    Hive.registerAdapter(UnspentCoinsInfoAdapter());
  }

  monero.onStartup();
  final _walletInfoSource = await Hive.openBox<WalletInfo>(WalletInfo.boxName);
  walletService = monero.createMoneroWalletService(_walletInfoSource);
  storage = FlutterSecureStorage();
  prefs = await SharedPreferences.getInstance();
  keysStorage = KeyService(storage!);
  WalletInfo walletInfo;
  late WalletCredentials credentials;
  try {
    // if (name?.isEmpty ?? true) {
    // name = await generateName();
    // }
    String name = "namee${Random().nextInt(10000000)}";
    final dirPath = await pathForWalletDir(name: name, type: WalletType.monero);
    final path = await pathForWallet(name: name, type: WalletType.monero);
    credentials =
        // creating a new wallet
        // monero.createMoneroNewWalletCredentials(
        //     name: name, language: "English");
        // restoring a previous wallet
        monero.createMoneroRestoreWalletFromSeedCredentials(
      name: name,
      height: 2580000,
      mnemonic: "",
    );
    walletInfo = WalletInfo.external(
        id: WalletBase.idFor(name, WalletType.monero),
        name: name,
        type: WalletType.monero,
        isRecovery: false,
        restoreHeight: credentials.height ?? 0,
        date: DateTime.now(),
        path: path,
        address: "",
        dirPath: dirPath);
    credentials.walletInfo = walletInfo;

    _walletCreationService = WalletCreationService(
      secureStorage: storage,
      sharedPreferences: prefs,
      walletService: walletService,
      keyService: keysStorage,
    );
    _walletCreationService.changeWalletType();
    // To restore from a seed
    final wallet = await
        // _walletCreationService.create(credentials);
        _walletCreationService.restoreFromSeed(credentials);
    // to create a new wallet
    // final wallet = await process(credentials);
    walletInfo.address = wallet.walletAddresses.address;
    print(walletInfo.address);
    await _walletInfoSource.add(walletInfo);
    walletBase?.close();
    walletBase = wallet as MoneroWalletBase;
  } catch (e, s) {
    print(e);
    print(s);
  }
  // print(walletBase);
  // loggerPrint(walletBase.toString());
  // loggerPrint("name: ${walletBase!.name}  seed: ${walletBase!.seed} id: "
  //     "${walletBase!.id} walletinfo: ${toStringForinfo(walletBase!.walletInfo)} type: ${walletBase!.type} balance: "
  //     "${walletBase!.balance.entries.first.value.available} currency: ${walletBase!.currency}");
  await walletBase?.connectToNode(
      node:
          Node(uri: "xmr-node.cakewallet.com:18081", type: WalletType.monero));
  walletBase!.rescan(height: credentials.height);
  walletBase!.getNodeHeight();
  runApp(MyApp());
}

String toStringForinfo(WalletInfo info) {
  return "id: ${info.id}  name: ${info.name} type: ${info.type} recovery: ${info.isRecovery}"
      " restoreheight: ${info.restoreHeight} timestamp: ${info.timestamp} dirPath: ${info.dirPath} "
      "path: ${info.path} address: ${info.address} addresses: ${info.addresses}";
}

Future<String> pathForWalletDir(
    {required String name, required WalletType type}) async {
  Directory root = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    root = (await getLibraryDirectory());
  }
  final prefix = walletTypeToString(type).toLowerCase();
  final walletsDir = Directory('${root.path}/wallets');
  final walletDire = Directory('${walletsDir.path}/$prefix/$name');

  if (!walletDire.existsSync()) {
    walletDire.createSync(recursive: true);
  }

  return walletDire.path;
}

Future<String> pathForWallet(
        {required String name, required WalletType type}) async =>
    await pathForWalletDir(name: name, type: type)
        .then((path) => path + '/$name');

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String? platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterLibmonero.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(getSyncingHeight());
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monero Plugin example app'),
        ),
        body: Center(
          child: ListView(
            children: [
              Text(
                  "Transactions:${walletBase!.transactionHistory!.transactions}"),
              TextButton(
                  onPressed: () async {
                    for (var bal in walletBase!.balance!.entries) {
                      loggerPrint(
                          "key: ${bal.key}, amount ${moneroAmountToString(amount: bal.value.available)}");
                    }
                  },
                  child: Text("amount")),
              TextButton(
                onPressed: () async {
                  Output output = Output(walletBase!); //
                  output.address =
                      "45ssGbDbLTnjdhpAm89PDpHpj6r5xWXBwL6Bh8hpy3PUcEnLgroo9vFJ9UE3HsAT5TTSk3Cqe2boJQHePAXisQSu9i6tz5A";
                  output.setCryptoAmount("0.00001011");
                  List<Output> outputs = [output];
                  Object tmp =
                      monero.createMoneroTransactionCreationCredentials(
                          outputs: outputs,
                          priority: monero.getDefaultTransactionPriority());
                  loggerPrint(tmp);
                  Future<PendingTransaction> awaitPendingTransaction =
                      walletBase!.createTransaction(tmp);
                  loggerPrint(output);
                  PendingMoneroTransaction pendingMoneroTransaction =
                      await awaitPendingTransaction as PendingMoneroTransaction;
                  loggerPrint(pendingMoneroTransaction);
                  loggerPrint(pendingMoneroTransaction.id);
                  loggerPrint(pendingMoneroTransaction.amountFormatted);
                  loggerPrint(pendingMoneroTransaction.feeFormatted);
                  loggerPrint(pendingMoneroTransaction
                      .pendingTransactionDescription.amount);
                  loggerPrint(pendingMoneroTransaction
                      .pendingTransactionDescription.hash);
                  loggerPrint(pendingMoneroTransaction
                      .pendingTransactionDescription.fee);
                  loggerPrint(pendingMoneroTransaction
                      .pendingTransactionDescription.pointerAddress);
                  try {
                    await pendingMoneroTransaction.commit();
                    loggerPrint(
                        "transaction ${pendingMoneroTransaction.id} has been sent");
                  } catch (e, s) {
                    loggerPrint("error");
                    loggerPrint(e);
                    loggerPrint(s);
                  }
                },
                child: Text("send Transaction"),
              ),
              // Text(
              //     "bob ${moneroAmountToString(amount: walletBase.transactionHistory.transactions.entries.first.value.amount)}"),
              FutureBuilder(
                future: walletBase!
                    .getNodeHeight(), // a previously-obtained Future<String> or null
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  List<Widget> children;
                  if (snapshot.hasData) {
                    children = <Widget>[
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Result: ${snapshot.data}'),
                      )
                    ];
                  } else if (snapshot.hasError) {
                    children = <Widget>[
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Error: ${snapshot.error}'),
                      )
                    ];
                  } else {
                    children = const <Widget>[
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Awaiting result...'),
                      )
                    ];
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: children,
                    ),
                  );
                },
              ),
            ],
          ),
          // Text(
          //     'Running on: $_platformVersion\n ${walletBase.getNodeHeight()}'),
        ),
      ),
    );
  }
}

void loggerPrint(core.Object? object) async {
  final utcTime = core.DateTime.now().toUtc().toString() + ": ";
  core.int defaultPrintLength = 1020 - utcTime.length;
  if (object == null || object.toString().length <= defaultPrintLength) {
    core.print("$utcTime$object");
  } else {
    core.String log = object.toString();
    core.int start = 0;
    core.int endIndex = defaultPrintLength;
    core.int logLength = log.length;
    core.int tmpLogLength = log.length;
    while (endIndex < logLength) {
      core.print(utcTime + log.substring(start, endIndex));
      endIndex += defaultPrintLength;
      start += defaultPrintLength;
      tmpLogLength -= defaultPrintLength;
    }
    if (tmpLogLength > 0) {
      core.print(utcTime + log.substring(start, logLength));
    }
  }
}
