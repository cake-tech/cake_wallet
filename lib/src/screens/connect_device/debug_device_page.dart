import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cw_ethereum/ethereum_client.dart';
import 'package:flutter/material.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:polyseed/polyseed.dart';

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

  // late BitcoinLedgerApp btc;
  var devices = <LedgerDevice>[];
  var status = "";
  LedgerDevice? selectedDevice = null;

  @override
  void initState() {
    super.initState();
    // btc = BitcoinLedgerApp(ledger);
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
                      // setState(() => status = "Loading");
                      // final path = await pathForWallet(name: "Ledger Test", type: WalletType.monero);
                      // try {
                      //   restoreMoneroWalletFromDevice(path: path, password: "CakeWallet", deviceName: e.id);
                      //   setState(() => status = "Success!");
                      // } on WalletRestoreFromKeysException catch (ex) {
                      //   setState(() {
                      //     status = "ERROR: ${ex.message}";
                      //   });
                      // }
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
                  DebugButton(
                    title: "Get Version",
                    method: "Version",
                    func: () async => {}// await btc.getVersion(selectedDevice!),
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
                    method: "BTC-Wallet",
                    func: () async => {}// await btc.getAccounts(selectedDevice!),
                  ),
                  DebugButton(
                    title: "Get Output",
                    method: "OutHash",
                    func: () async => Address.addressToOutputScript("bc1q4aacwm9f9ayukulk7sq4h75ge0pwp6r8nzvt7h").toHexString(),
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
