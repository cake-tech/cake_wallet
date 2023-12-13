import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
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
  final imageBackup = Image.asset('assets/images/backup.png');
  final ledger = Ledger(
    options: LedgerOptions(
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


  @override
  void initState() {
    super.initState();

    devices = ledger.devices;
    print(ledger.devices);
    ledger.scan().listen((device) => setState(() {
          devices.add(device);
        }));
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
              children: devices.map((e) {
                return OptionTile(
                  onPressed: () async {
                    // final path = await pathForWallet(name: "Ledger Test", type: WalletType.monero);
                    // try {
                    //   restoreMoneroWalletFromDevice(
                    //       path: path,
                    //       password: "Konsti",
                    //       deviceName: e.id
                    //   );
                    // } catch (ex) {
                    //   print((ex as WalletRestoreFromKeysException));
                    // }

                    final btc = BitcoinLedgerApp(ledger);
                    await ledger.connect(e);
                    final version = await btc.getVersion(e);
                    print(version.name);
                    print(version.version);
                    await ledger.disconnect(e);
                  },
                  title: e.name,
                  description: e.connectionType.name,
                  image: imageBackup,
                );
              }).toList(),
            ),
          )),
    );
  }
}
