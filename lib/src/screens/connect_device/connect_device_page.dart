import 'dart:typed_data';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:flutter/material.dart';
import 'package:ledger_algorand/ledger_algorand.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectDevicePage extends BasePage {
  @override
  String get title => "Connect Ledger";

  @override
  Widget body(BuildContext context) => ConnectDevicePageBody();
}

class ConnectDevicePageBody extends StatefulWidget {
  @override
  ConnectDevicePageBodyState createState() => ConnectDevicePageBodyState();
}

class ConnectDevicePageBodyState extends State<ConnectDevicePageBody> {
  final imageLedger = Image.asset(
    'assets/images/ledger_icon_black.png',
    width: 40,
  );
  final ledger = Ledger(
    options: LedgerOptions(
      scanMode: ScanMode.balanced,
      maxScanDuration: const Duration(milliseconds: 5000),
    ),
    onPermissionRequest: (status) async {
      Map<Permission, PermissionStatus> statuses = await [
        // Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ].request();

      if (status != BleStatus.ready) {
        return false;
      }

      return statuses.values.where((status) => status.isDenied).isEmpty;
    },
  );
  final client = EthereumClient();

  late BitcoinLedgerApp btc;
  late AlgorandLedgerApp algo;
  var devices = <LedgerDevice>[];
  var status = "";
  LedgerDevice? selectedDevice = null;

  @override
  void initState() {
    super.initState();
    btc = BitcoinLedgerApp(ledger);
    algo = AlgorandLedgerApp(ledger);
  }

  @override
  void dispose() {
    super.dispose();
    ledger.close(ConnectionType.ble);
    ledger.close(ConnectionType.usb);
  }

  Future<void> reconnectCurrentDevice() async {
    // await ledger.disconnect(selectedDevice!);
    // await ledger.connect(selectedDevice!);
  }

  Future<void> disconnectCurrentDevice() async {
    await ledger.disconnect(selectedDevice!);
    setState(() {
      selectedDevice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...devices.map((e) {
                  return OptionTile(
                    onPressed: () async {
                      // setState(() {
                      //   status = "Loading";
                      // });
                      // final path = await pathForWallet(name: "Ledger Test", type: WalletType.monero);
                      // try {
                      //   restoreMoneroWalletFromDevice(
                      //       path: path,
                      //       password: "Konsti",
                      //       deviceName: e.id
                      //   );
                      //   setState(() {
                      //     status = "Erfolg!";
                      //   });
                      // } on WalletRestoreFromKeysException catch (ex) {
                      //   setState(() {
                      //     status = "ERROR: " + ex.message;
                      //   });
                      // }

                      await ledger.connect(e);
                      setState(() {
                        selectedDevice = e;
                      });
                    },
                    title: e.name,
                    description: e.connectionType.name,
                    image: imageLedger,
                  );
                }).toList(),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(status),
                ),
                if (selectedDevice != null) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                        text: "Get Version",
                        onPressed: () async {
                          try {
                            setState(() => status = "Sending...");
                            final version = await btc.getVersion(selectedDevice!);
                            setState(() => status = "${version.version}");
                            // print(version.name);
                            // print(version.version);
                            // reconnectCurrentDevice();
                          } on LedgerException catch (ex) {
                            setState(
                                () => status = "${ex.errorCode.toRadixString(16)} ${ex.message}");
                            print("${ex.errorCode.toRadixString(16)} ${ex.message}");
                            disconnectCurrentDevice();
                          }
                        },
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                        text: "Get Master Fingerprint",
                        onPressed: () async {
                          try {
                            setState(() => status = "Sending...");
                            final acc = await btc.getMasterFingerprint(selectedDevice!);
                            setState(() => status = "Master Fingerprint: ${acc}");
                            print("Master Fingerprint: ${acc}");
                          } on LedgerException catch (ex) {
                            setState(
                                    () => status = "${ex.errorCode.toRadixString(16)} ${ex.message}");
                            print("${ex.errorCode.toRadixString(16)} ${ex.message}");
                          }
                        },
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                        text: "Get Wallet Address",
                        onPressed: () async {
                          try {
                            final acc = await btc.getXPubKey(selectedDevice!);
                            setState(() => status = "BTC-Wallet: ${acc}");
                            print("BTC-Wallet: ${acc}");
                            // reconnectCurrentDevice();
                          } on LedgerException catch (ex) {
                            setState(
                                () => status = "${ex.errorCode.toRadixString(16)} ${ex.message}");
                            print("${ex.errorCode.toRadixString(16)} ${ex.message}");
                            // disconnectCurrentDevice();
                          }
                        },
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                        text: "Send Money",
                        onPressed: () async {
                          try {
                            // final acc = await eth.getAccounts(selectedDevice!);
                            // setState(() => status = "Eth-Wallet: ${acc.first}");
                            await signMessage();
                          } on LedgerException catch (ex) {
                            setState(
                                () => status = "${ex.errorCode.toRadixString(16)} ${ex.message}");
                            print("${ex.errorCode.toRadixString(16)} ${ex.message}");
                            // disconnectCurrentDevice();
                          }
                        },
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                        text: "Disconnect",
                        onPressed: () => disconnectCurrentDevice(),
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white),
                  ),
                ],
                if (selectedDevice == null) ...[
                  PrimaryButton(
                      text: "Refresh BLE",
                      onPressed: () async {
                        setState(() => devices = []);
                        ledger.scan().listen((device) => setState(() {
                              devices.add(device);
                            }));
                      },
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                        text: "Use USB",
                        onPressed: () async {
                          final dev = await ledger.listUsbDevices();
                          setState(() => devices = dev);
                        },
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white),
                  ),
                ],
              ],
            ),
          )),
    );
  }

  Future<void> signMessage() async {
    // final ticker = "USDC";
    // final decimals = 6;
    // final infoSig = "3045022100b2e358726e4e6a6752cf344017c0e9d45b9a904120758d45f61b2804f9ad5299022015161ef28d8c4481bd9432c13562def9cce688bcfec896ef244c9a213f106cdd";
    // final chainId = 1;
    // final address = "A0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    //
    // await eth.provideERC20TokenInformation(selectedDevice!,
    //   erc20Ticker: ticker,
    //   erc20ContractAddress: address,
    //   decimals: decimals,
    //   chainId: chainId,
    //   tokenInformationSignature: infoSig
    // );
  }

  Future<void> sendMoney(String from) async {
    final txRaw = [
      0x02,
      0xed,
      0x01,
      0x80,
      0x84,
      0x01,
      0x62,
      0x73,
      0xad,
      0x85,
      0x0f,
      0x36,
      0xd6,
      0x1c,
      0x6d,
      0x80,
      0x94,
      0xcf,
      0x99,
      0x56,
      0x98,
      0x90,
      0x77,
      0x1d,
      0x86,
      0x9b,
      0xfc,
      0x28,
      0xc7,
      0x76,
      0xd0,
      0x7f,
      0x59,
      0xb0,
      0x63,
      0x6d,
      0x72,
      0x87,
      0x23,
      0x86,
      0xf2,
      0x6f,
      0xc1,
      0x00,
      0x00,
      0x80,
      0xc0
    ];
    final transaction = Uint8List.fromList(txRaw);
    // final signedTx = await eth.signTransaction(selectedDevice!, transaction);

    // print(signedTx);
  }
}
