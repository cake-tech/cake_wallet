import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/dotted_divider.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/manufacturer_option_tile.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/view_model/restore/wallet_restore_from_qr_code.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

class SelectDeviceManufacturerPage extends BasePage {
  SelectDeviceManufacturerPage({
    this.showUnavailable = true,
    this.onSelect,
    this.availableHardwareWalletTypes,
  });

  final bool showUnavailable;
  final void Function(BuildContext, HardwareWalletType)? onSelect;
  final List<HardwareWalletType>? availableHardwareWalletTypes;

  @override
  String get title => S.current.select_manufacturer_title;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.regular;

  ColorFilter get _colorFilter =>
      ColorFilter.mode(currentTheme.colorScheme.onSurface, BlendMode.srcIn);

  List<_DeviceManufacturer> get availableManufacturers => [
        _DeviceManufacturer(
          image: SvgPicture.asset(
            'assets/images/hardware_wallet/ledger_man.svg',
            height: 25,
            colorFilter: _colorFilter,
          ),
          hardwareWalletType: HardwareWalletType.ledger,
        ),
        if (Platform.isAndroid) ...[
          _DeviceManufacturer(
            image: SvgPicture.asset(
              'assets/images/hardware_wallet/trezor_man.svg',
              height: 25,
              colorFilter: _colorFilter,
            ),
            hardwareWalletType: HardwareWalletType.trezor,
            tag: S.current.new_tag,
          ),
          _DeviceManufacturer(
            image: SvgPicture.asset(
              'assets/images/hardware_wallet/bitbox_man.svg',
              height: 25,
              colorFilter: _colorFilter,
            ),
            hardwareWalletType: HardwareWalletType.bitbox,
            tag: S.current.new_tag,
          ),
        ],
        _DeviceManufacturer(
          image: SvgPicture.asset(
            'assets/images/hardware_wallet/cupcake_man.svg',
            height: 25,
            colorFilter: _colorFilter,
          ),
          hardwareWalletType: HardwareWalletType.cupcake,
          tag: S.current.new_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset(
            'assets/images/hardware_wallet/coldcard_man.svg',
            height: 25,
            colorFilter: _colorFilter,
          ),
          hardwareWalletType: HardwareWalletType.coldcard,
          tag: S.current.new_tag,
        ),
        // _DeviceManufacturer(
        //   image: SvgPicture.asset(
        //     'assets/images/hardware_wallet/seedsigner_man.svg',
        //     height: 25,
        //     colorFilter: _colorFilter,
        //   ),
        //   hardwareWalletType: HardwareWalletType.seedsigner,
        //   tag: S.current.new_tag,
        // ),
      ]
          .where((e) => availableHardwareWalletTypes == null
              ? ![HardwareWalletType.cupcake].contains(e.hardwareWalletType)
              : availableHardwareWalletTypes!.contains(e.hardwareWalletType))
          .toList();

  List<_DeviceManufacturer> get comingManufacturers => [
        if (!Platform.isAndroid) ...[
          _DeviceManufacturer(
            image: SvgPicture.asset(
              'assets/images/hardware_wallet/bitbox_man.svg',
              height: 25,
              colorFilter: _colorFilter,
            ),
            hardwareWalletType: HardwareWalletType.bitbox,
            tag: S.current.coming_soon_tag,
          ),
        ],
        _DeviceManufacturer(
          image: SvgPicture.asset(
            'assets/images/hardware_wallet/seedsigner_man.svg',
            height: 25,
            colorFilter: _colorFilter,
          ),
          hardwareWalletType: HardwareWalletType.seedsigner,
          tag: S.current.coming_soon_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset(
            'assets/images/hardware_wallet/foundation_man.svg',
            height: 25,
            colorFilter: _colorFilter,
          ),
          tag: S.current.coming_soon_tag,
        ),
        _DeviceManufacturer(
          image: SvgPicture.asset(
            'assets/images/hardware_wallet/keystone_man.svg',
            height: 25,
            colorFilter: _colorFilter,
          ),
          tag: S.current.coming_soon_tag,
        ),
      ];

  @override
  Widget body(BuildContext context) => Container(
        child: Center(
          child: Container(
            padding: EdgeInsets.only(left: 24, right: 24),
            height: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...availableManufacturers.map(
                    (manufacturer) => Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: ManufacturerOptionTile(
                        image: manufacturer.image,
                        tag: manufacturer.tag,
                        onPressed: () {
                          if (onSelect != null)
                            return onSelect!.call(context, manufacturer.hardwareWalletType!);

                          if (isAirgappedWallet(manufacturer.hardwareWalletType)) {
                            _onScanQRCode(context, manufacturer.hardwareWalletType!);
                          } else if (manufacturer.hardwareWalletType != null) {
                            Navigator.pushNamed(context, Routes.connectHardwareWallet,
                                arguments: [manufacturer.hardwareWalletType]);
                          }
                        },
                      ),
                    ),
                  ),
                  if (showUnavailable) ...[
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
                          onPressed: () =>
                              Fluttertoast.showToast(msg: 'One more tap and it might work'),
                          // Ester egg

                          isUnavailable: true,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      );

  bool isAirgappedWallet(HardwareWalletType? type) => [
        HardwareWalletType.cupcake,
        HardwareWalletType.coldcard,
        HardwareWalletType.seedsigner,
        HardwareWalletType.keystone,
      ].contains(type);

  bool isRestoring = false;

  Future<void> _onScanQRCode(BuildContext context, HardwareWalletType type) async {
    final isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);

    if (!isCameraPermissionGranted) return;
    try {
      if (isRestoring) return;

      isRestoring = true;

      final restoredWallet = await WalletRestoreFromQRCode.scanQRCodeForRestoring(context);

      final params = {
        'walletType': restoredWallet.type,
        'restoredWallet': restoredWallet,
        'hardwareWalletType': type,
      };

      Navigator.pushNamed(context, Routes.restoreWallet, arguments: params)
          .then((_) => isRestoring = false);
    } catch (e) {
      printV(e.toString());
    }
  }
}

class _DeviceManufacturer {
  final SvgPicture image;
  final HardwareWalletType? hardwareWalletType;
  final String? tag;

  _DeviceManufacturer({required this.image, this.hardwareWalletType, this.tag});
}
