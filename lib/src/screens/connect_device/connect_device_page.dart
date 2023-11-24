import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectDevicePage extends BasePage {

  @override
  String get title => "Connect Ledger";

  final imageBackup = Image.asset('assets/images/backup.png');

  @override
  Widget body(BuildContext context) {
    return Center(
      child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                OptionTile(
                    onPressed: () {
                      final options = LedgerOptions(
                        maxScanDuration: const Duration(milliseconds: 5000),
                      );


                      final ledger = Ledger(
                        options: options,
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

                      ledger.scan().listen((device) => print(device.name));
                    },
                    title: "Ledger",
                    description: S.of(context).restore_description_from_seed_keys, image: imageBackup,),
              ],
            ),
          )),
    );
  }
}
