import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/manufacturer_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SelectDeviceManufacturerPage extends BasePage {
  SelectDeviceManufacturerPage();

  final imageLedger = SvgPicture.asset('assets/images/hardware_wallet/ledger_man.svg', height: 25);
  final imageBitbox = SvgPicture.asset('assets/images/hardware_wallet/bitbox_man.svg', height: 12);
  final imageTrezor = SvgPicture.asset('assets/images/hardware_wallet/trezor_man.svg', height: 20);
  final imageColdcard =
      SvgPicture.asset('assets/images/hardware_wallet/coldcard_man.svg', height: 12);

  @override
  String get title => S.current.restore_title_from_hardware_wallet;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  @override
  Widget body(BuildContext context) => Container(
        child: Center(
          child: Container(
            padding: EdgeInsets.only(left: 24, right: 24),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ManufacturerOptionTile(
                    image: imageLedger,
                    supportedDevices: "Nano S, Nano X, Flex & Stax",
                    onPressed: () {},
                    isDarkTheme: currentTheme.isDark,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ManufacturerOptionTile(
                    image: imageBitbox,
                    tag: "Soon",
                    supportedDevices: "BitBox02 & BitBox02 Nova",
                    onPressed: () {},
                    isDarkTheme: currentTheme.isDark,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ManufacturerOptionTile(
                    image: imageTrezor,
                    tag: "Soon",
                    supportedDevices: "Safe 5, Safe 3 & Model One",
                    onPressed: () {},
                    isDarkTheme: currentTheme.isDark,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: ManufacturerOptionTile(
                    image: imageColdcard,
                    supportedDevices: "COLDCARD Q",
                    onPressed: () {},
                    isDarkTheme: currentTheme.isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
