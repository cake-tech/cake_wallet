import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:ledger_ethereum/ledger_ethereum.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
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
  final conLedger = Ledger(options: LedgerOptions(
    scanMode: ScanMode.balanced,));

  late EthereumLedgerApp eth;
  var devices = <LedgerDevice>[];
  var status = "";
  var counter = 0;
  LedgerDevice? selectedDevice = null;

  @override
  void initState() {
    super.initState();
    eth = EthereumLedgerApp(conLedger);
  }

  @override
  void dispose() {
    super.dispose();
    conLedger.close(ConnectionType.ble);
    conLedger.close(ConnectionType.usb);
  }

  Future<void> reconnectCurrentDevice() async {
    // await ledger.disconnect(selectedDevice!);
    // await ledger.connect(selectedDevice!);
  }

  Future<void> disconnectCurrentDevice() async {
    await conLedger.disconnect(selectedDevice!);
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
                    func: () async => await eth.getVersion(selectedDevice!),
                  ),
                  DebugButton(
                    title: "Get Master Fingerprint",
                    method: "Master Fingerprint",
                    func: () async => {}// await btc.getMasterFingerprint(selectedDevice!),
                  ),
                  DebugButton(
                    title: "Get XPub",
                    method: "XPub",
                    func: () async => {}// await btc.getXPubKey(selectedDevice!, derivationPath: "m/84'/0'/0'"),
                  ),
                  DebugButton(
                    title: "Get Wallet Address",
                    method: "Wallet Address",
                    func: () async {
                      // setState(() => counter++);
                      // final derivationPath = "m/44'/60'/$counter'/0/0";
                      // print(derivationPath);
                      // return await eth.getAccounts(selectedDevice!, derivationPath);
                      // return await ethereum!.getHardwareWalletAccounts(selectedDevice!);
                      },
                  ),
                  DebugButton(
                    title: "Get Output",
                    method: "OutHash",
                    func: () async => {}//Address.addressToOutputScript("bc1q4aacwm9f9ayukulk7sq4h75ge0pwp6r8nzvt7h").toHexString(),
                  ),
                  DebugButton(
                    title: "Sign Message",
                    method: "Sig",
                    func: () async {}
                    //   final message = magicHashMessage('CakeWallet');
                    //   final result = await btc.signMessage(selectedDevice!, message: message);
                    //   return base64.encode(result);
                    // },
                  ),
                  DebugButton(
                    title: "Send Money",
                    method: "Sig",
                    func: () async {}
                    //   final psbt = PsbtV2();
                    //   final psbtBuf = base64.decode(
                    //       "cHNidP8BAHsCAAAAAk1upP3MCirtbu5vaCq+aG+1XAAtCD5H2g4rUYvxZA+7AAAAAAD9////zEm9RNUErupcFctJ+/6BMtZpbdlA8i9MbJ9XRI5cekIFAAAAAP3///8BTRcAAAAAAAAWABSve4dsqS9Jy3P29AFb+ojLwuDoZwAAAAABBAECAQUBAQAAAAA=");
                    //
                    //   psbt.deserialize(psbtBuf);
                    //   final result = await btc.signPsbt(selectedDevice!, psbt: psbt);
                    //   return result.toHexString();
                    // },
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
