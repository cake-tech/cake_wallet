import 'dart:convert';

import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polyseed/polyseed.dart';

class DebugDevicePage extends BasePage {
  @override
  String get title => "Connect Ledger";

  @override
  Widget body(BuildContext context) => DebugDevicePageBody();
}

class DebugDevicePageBody extends StatefulWidget {
  @override
  DebugDevicePageBodyState createState() => DebugDevicePageBodyState();
}

class DebugDevicePageBodyState extends State<DebugDevicePageBody> {
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

  late BitcoinLedgerApp btc;
  var devices = <LedgerDevice>[];
  var status = "";
  var counter = 0;
  LedgerDevice? selectedDevice = null;

  @override
  void initState() {
    super.initState();
    btc = BitcoinLedgerApp(ledger);
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
    setState(() => selectedDevice = null);
  }

  @override
  Widget build(BuildContext context) {
    final imageLedger = 'assets/images/ledger_nano.png';

    return Center(
      child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(status),
                ),
                if (selectedDevice != null) ...[
                  DebugButton(
                    title: "Get Version",
                    method: "Version",
                    func: () async => await btc.getVersion(selectedDevice!),
                  ),
                  DebugButton(
                    title: "Get Master Fingerprint",
                    method: "Master Fingerprint",
                    func: () async => await btc.getMasterFingerprint(selectedDevice!),
                  ),
                  DebugButton(
                    title: "Get XPub",
                    method: "XPub",
                    func: () async => await btc.getXPubKey(selectedDevice!, derivationPath: "m/84'/0'/$counter'"),
                  ),
                  DebugButton(
                    title: "Get Wallet Address",
                    method: "Wallet Address",
                    func: () async {
                      setState(() => counter++);
                      final derivationPath = "m/84'/0'/$counter'";
                      return await btc.getAccounts(selectedDevice!, accountsDerivationPath: derivationPath);
                      // return await ethereum!.getHardwareWalletAccounts(selectedDevice!);
                      },
                  ),
                  DebugButton(
                    title: "Send Money",
                    method: "Sig",
                    func: () async {
                      final psbt = PsbtV2();
                      final psbtBuf = base64.decode(
                          "cHNidP8BAgQCAAAAAQQBAQEFAQIAAQ4guw9k8YtRKw7aRz4ILQBctW9ovipob+5u7SoKzP2kbk0BDwQAAAAAARAE/////wEBH+UeAAAAAAAAFgAUp2rS6ZK5wEZWSXYylPoeCj/Rr/EiBgN8TLsZj7AQJvWjBFAbNzeOgwfinbbN22Uf1sbfrjNB+BirTem6VAAAgAAAAIAAAACAAAAAAAAAAAAAAQQU5O2xDsWHHVw4tXnlq2mA7n5uniYBAwjoAwAAAAAAAAABBBQ194P6Zw1yH7EcPLISuNjWZ/knaQEDCIgTAAAAAAAAAA==");

                      psbt.deserialize(psbtBuf);
                      final result = await btc.signPsbt(selectedDevice!, psbt: psbt);
                      return result.toHexString();
                    },
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
                  ...devices
                      .map(
                        (device) => Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: DeviceTile(
                        onPressed: () {
                          setState(() => selectedDevice = device);
                          ledger.connect(device);
                        },
                        title: device.name,
                        leading: imageLedger,
                        connectionType: device.connectionType,
                      ),
                    ),
                  )
                      .toList(),
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

  Widget DebugButton(
      {required String title, required String method, required Future<dynamic> Function() func}) {
    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: PrimaryButton(
          text: title,
          onPressed: () async {
            try {
              setState(() => status = "Sending...");
              final acc = await func();
              setState(() => status = "$method: $acc");
              print("$method: $acc");
            } on LedgerException catch (ex) {
              setState(() => status = "${ex.errorCode.toRadixString(16)} ${ex.message}");
              print("${ex.errorCode.toRadixString(16)} ${ex.message}");
            }
          },
          color: Theme.of(context).primaryColor,
          textColor: Colors.white),
    );
  }
}
