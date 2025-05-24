// import 'dart:typed_data';
//
// import 'package:basic_utils/basic_utils.dart';
// import 'package:bitcoin_base/bitcoin_base.dart';
// import 'package:cake_wallet/src/screens/base_page.dart';
// import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
// import 'package:cake_wallet/src/widgets/primary_button.dart';
// import 'package:cake_wallet/utils/responsive_layout_util.dart';
// import 'package:flutter/material.dart';
// import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
// import 'package:ledger_litecoin/ledger_litecoin.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class DebugDevicePage extends BasePage {
//   @override
//   String get title => "Connect Ledger";
//
//   @override
//   Widget body(BuildContext context) => DebugDevicePageBody();
// }
//
// class DebugDevicePageBody extends StatefulWidget {
//   @override
//   DebugDevicePageBodyState createState() => DebugDevicePageBodyState();
// }
//
// class DebugDevicePageBodyState extends State<DebugDevicePageBody> {
//   final imageLedger = Image.asset(
//     'assets/images/ledger_icon_black.png',
//     width: 40,
//   );
//   final ledger = Ledger(
//     options: LedgerOptions(
//       scanMode: ScanMode.balanced,
//       maxScanDuration: const Duration(milliseconds: 5000),
//     ),
//     onPermissionRequest: (status) async {
//       Map<Permission, PermissionStatus> statuses = await [
//         // Permission.location,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.bluetoothAdvertise,
//       ].request();
//
//       if (status != BleStatus.ready) {
//         return false;
//       }
//
//       return statuses.values.where((status) => status.isDenied).isEmpty;
//     },
//   );
//
//   // late BitcoinLedgerApp btc;
//   late LitecoinLedgerApp ltc;
//
//   var devices = <LedgerDevice>[];
//   var status = "";
//   var counter = 0;
//   LedgerDevice? selectedDevice = null;
//
//   @override
//   void initState() {
//     super.initState();
//     // btc = BitcoinLedgerApp(ledger);
//     ltc = LitecoinLedgerApp(ledger);
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     ledger.close(ConnectionType.ble);
//     ledger.close(ConnectionType.usb);
//   }
//
//   Future<void> reconnectCurrentDevice() async {
//     // await ledger.disconnect(selectedDevice!);
//     // await ledger.connect(selectedDevice!);
//   }
//
//   Future<void> disconnectCurrentDevice() async {
//     await ledger.disconnect(selectedDevice!);
//     setState(() => selectedDevice = null);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final imageLedger = 'assets/images/hardware_wallet/ledger_nano_x.png';
//
//     return Center(
//       child: Container(
//           width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
//           height: double.infinity,
//           padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: EdgeInsets.only(top: 20),
//                   child: Text(status),
//                 ),
//                 if (selectedDevice != null) ...[
//                   DebugButton(
//                     title: "Get Version",
//                     method: "Version",
//                     // func: () async => await btc.getVersion(selectedDevice!),
//                     func: () async => await ltc.getVersion(selectedDevice!),
//                   ),
//                   DebugButton(
//                     title: "Get Wallet Address",
//                     method: "Wallet Address",
//                     func: () async {
//                       setState(() => counter++);
//                       final derivationPath = "m/84'/2'/0'/0/0";
//                       return await ltc.getAccounts(selectedDevice!,
//                           accountsDerivationPath: derivationPath);
//                       // return await btc.getAccounts(selectedDevice!, accountsDerivationPath: derivationPath);
//                       // return await ethereum!.getHardwareWalletAccounts(selectedDevice!);
//                     },
//                   ),
//                   DebugButton(
//                     title: "Send Money",
//                     method: "Raw Tx",
//                     func: sendMoney
//                   ),
//                   Padding(
//                     padding: EdgeInsets.only(top: 20),
//                     child: PrimaryButton(
//                         text: "Disconnect",
//                         onPressed: () => disconnectCurrentDevice(),
//                         color: Theme.of(context).colorScheme.primary,
//                         textColor: Theme.of(context).colorScheme.onPrimary),
//                   ),
//                 ],
//                 if (selectedDevice == null) ...[
//                   ...devices
//                       .map(
//                         (device) => Padding(
//                           padding: EdgeInsets.only(bottom: 20),
//                           child: DeviceTile(
//                             onPressed: () {
//                               setState(() => selectedDevice = device);
//                               ledger.connect(device);
//                             },
//                             title: device.name,
//                             leading: imageLedger,
//                             connectionType: device.connectionType,
//                           ),
//                         ),
//                       )
//                       .toList(),
//                   PrimaryButton(
//                       text: "Refresh BLE",
//                       onPressed: () async {
//                         setState(() => devices = []);
//                         ledger.scan().listen((device) => setState(() {
//                               devices.add(device);
//                             }));
//                       },
//                       color: Theme.of(context).colorScheme.primary,
//                       textColor: Theme.of(context).colorScheme.onPrimary),
//                   Padding(
//                     padding: EdgeInsets.only(top: 20),
//                     child: PrimaryButton(
//                         text: "Use USB",
//                         onPressed: () async {
//                           final dev = await ledger.listUsbDevices();
//                           setState(() => devices = dev);
//                         },
//                         color: Theme.of(context).colorScheme.primary,
//                         textColor: Theme.of(context).colorScheme.onPrimary),
//                   ),
//                 ],
//               ],
//             ),
//           )),
//     );
//   }
//
//   Future<String> sendMoney() async {
//     final readyInputs = [
//       LedgerTransaction(
//         rawTx: "010000000001018c055c85c3724c98842d27712771dd0de139711f5940bba2df4615c5522184740000000017160014faf7f6dfb4e70798b92c93f33b4c51024491829df0ffffff022b05c70000000000160014f489f947fd13a1fb44ac168427081d3f30b6ce0cde9dd82e0000000017a914d5eca376cb49d65031220ff9093b7d407073ed0d8702483045022100f648c9f6a9b8f35b6ec29bbfae312c95ed3d56ce6a3f177d994efe90562ec4bd02205b82ce2c94bc0c9d152c3afc668b200bd82f48d6a14e83c66ba0f154cd5f69190121038f1dca119420d4aa7ad04af1c0d65304723789cccc56d335b18692390437f35900000000",
//         outputIndex: 0,
//         ownerPublicKey:
//             HexUtils.decode("03b2e67958ed3356e329e05cf94c3bee6b20c17175ac3b2a1278e073bf44f5d6ec"),
//         ownerDerivationPath: "m/84'/2'/0'/0/0",
//         sequence: 0xffffffff,
//       )
//     ];
//
//     final outputs = [
//       BitcoinOutput(
//           address: P2wpkhAddress.fromAddress(
//               address: "ltc1qn0g5e36xaj07lqj6w9xn52ng07hud42g3jf5ps",
//               network: LitecoinNetwork.mainnet),
//           value: BigInt.from(1000000)),
//       BitcoinOutput(
//           address: P2wpkhAddress.fromAddress(
//               address: "ltc1qrx29qz4ghu4j0xk37ptgk7034cwpmjyxhrcnk9",
//               network: LitecoinNetwork.mainnet),
//           value: BigInt.from(12042705)),
//     ];
//     return await ltc.createTransaction(selectedDevice!,
//         inputs: readyInputs,
//         outputs: outputs
//             .map((e) => TransactionOutput.fromBigInt(
//                 e.value, Uint8List.fromList(e.address.toScriptPubKey().toBytes())))
//             .toList(),
//         sigHashType: 0x01,
//         additionals: ["bech32"],
//         isSegWit: true,
//         useTrustedInputForSegwit: true);
//   }
//
//   Widget DebugButton(
//       {required String title, required String method, required Future<dynamic> Function() func}) {
//     return Padding(
//       padding: EdgeInsets.only(top: 20),
//       child: PrimaryButton(
//           text: title,
//           onPressed: () async {
//             try {
//               setState(() => status = "Sending...");
//               final acc = await func();
//               setState(() => status = "$method: $acc");
//               printV("$method: $acc");
//             } on LedgerException catch (ex) {
//               setState(() => status = "${ex.errorCode.toRadixString(16)} ${ex.message}");
//               printV("${ex.errorCode.toRadixString(16)} ${ex.message}");
//             }
//           },
//           color: Theme.of(context).colorScheme.primary,
//           textColor: Theme.of(context).colorScheme.onPrimary),
//     );
//   }
// }
