import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/api/wallet_manager.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:monero/monero.dart' as monero_dart;
import 'package:monero/src/ledger.dart';
import 'package:monero/src/generated_bindings_monero.g.dart' as monero_gen;
import 'package:permission_handler/permission_handler.dart';

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

  var devices = <LedgerDevice>[];
  var status = "";
  var counter = 0;
  LedgerDevice? selectedDevice = null;

  @override
  void initState() {
    super.initState();
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
                  // DebugButton(
                  //   title: "Get Master Fingerprint",
                  //   method: "Master Fingerprint",
                  //   func: () async => hex.encode(await btc.getMasterFingerprint(selectedDevice!)),
                  // ),

                  DebugButton(
                    title: "enable logs",
                    method: "enable logs",
                    func: () async => enableLedgerExchange(wptr!, ledger, selectedDevice!),
                  ),
                  DebugButton(
                    title: "enableLedgerExchange",
                    method: "enableLedgerExchange",
                    func: () async => enableLedgerExchange(wptr!, ledger, selectedDevice!),
                  ),
                  DebugButton(
                    title: "disableLedgerExchange",
                    method: "disableLedgerExchange",
                    func: () async => disableLedgerExchange(),
                  ),

                  DebugButton(
                    title: "Create Wallet",
                    method: "Sig",
                    func: () async {
                      final path =
                          await pathForWallet(name: "Ledger Test", type: WalletType.monero);
                      print(path);
                      final dir = Directory(path);
                      if (dir.existsSync()) await dir.delete(recursive: true);

                      final wmAddr = wmPtr.address;
                      final resAddr = await Isolate.run(() {
                        final res = monero_gen.MoneroC(DynamicLibrary.open(monero_dart.libPath))
                            .MONERO_WalletManager_createWalletFromDevice(
                          Pointer.fromAddress(wmAddr),
                          path.toNativeUtf8().cast(),
                          'Cake'.toNativeUtf8().cast(),
                          0,
                          "Ledger".toNativeUtf8().cast(),
                          0,
                          "".toNativeUtf8().cast(),
                          ";".toNativeUtf8().cast(),
                          ";".toNativeUtf8().cast(),
                          1,
                        );

                        return res.address;
                      });

                      final res = Pointer<Void>.fromAddress(resAddr);

                      print(monero_dart.Wallet_errorString(res));
                      print(monero_dart.Wallet_status(res));
                      print(monero_dart.Wallet_address(res));

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
                      ledger.scan().listen((device) => setState(() => devices.add(device)));
                    },
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: PrimaryButton(
                      text: "Use USB",
                      onPressed: () async {
                        final dev = await ledger.listUsbDevices();
                        setState(() => devices = dev);
                      },
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                    ),
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
