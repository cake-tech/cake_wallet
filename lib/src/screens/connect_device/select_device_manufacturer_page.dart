import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/dotted_divider.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/manufacturer_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SelectDeviceManufacturerPage extends BasePage {
  SelectDeviceManufacturerPage();

  final imageTrezor = SvgPicture.asset('assets/images/hardware_wallet/trezor_man.svg', height: 20);

  @override
  String get title => S.current.restore_title_from_hardware_wallet;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  List<_DeviceManufacturer> get availableManufacturers => [
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/ledger_man.svg', height: 25),
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/bitbox_man.svg', height: 25),
          tag: S.current.new_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/coldcard_man.svg', height: 12),
          tag: S.current.new_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/seedsigner_man.svg', height: 25),
          tag: S.current.new_tag,
        ),
      ];

  List<_DeviceManufacturer> get comingManufacturers => [
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/trezor_man.svg', height: 20),
          tag: S.current.coming_soon_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/foundation_man.svg', height: 20),
          tag: S.current.coming_soon_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset('assets/images/hardware_wallet/keystone_man.svg', height: 20),
          tag: S.current.coming_soon_tag,
        ),
      ];

  @override
  Widget body(BuildContext context) => Container(
        child: Center(
          child: Container(
            padding: EdgeInsets.only(left: 24, right: 24),
            child: Column(
              children: [
                ...availableManufacturers.map(
                  (manufacturer) => Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ManufacturerOptionTile(
                      image: manufacturer.image,
                      tag: manufacturer.tag,
                      // supportedDevices: "Nano S, Nano X, Flex & Stax",
                      onPressed: () {},
                      isDarkTheme: currentTheme.isDark,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 10),
                  child: DottedDivider(color: Theme.of(context).colorScheme.surfaceContainer),
                ),
                ...comingManufacturers.map(
                      (manufacturer) => Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ManufacturerOptionTile(
                      image: manufacturer.image,
                      tag: manufacturer.tag,
                      onPressed: () {},
                      isDarkTheme: currentTheme.isDark,
                      isUnavailable: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DeviceManufacturer {
  final SvgPicture image;
  final String? tag;

  _DeviceManufacturer({required this.image, this.tag});
}
