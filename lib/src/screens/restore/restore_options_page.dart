import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/pages/app_backup/backup_restore_page.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/wallet_restore_from_qr_code.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class RestoreOptionsPage extends BasePage {
  RestoreOptionsPage({required this.isNewInstall, required this.backupRestoreFlow});

  @override
  String get title => S.current.restore_restore_wallet;
  final bool isNewInstall;
  final BackupRestoreFlow backupRestoreFlow;
  final _isScanning = ValueNotifier(false);

  String get imageRestoreHWPath => currentTheme.type == ThemeType.dark
      ? 'assets/images/restore_hw_dark.png'
      : 'assets/images/restore_hw.png';

  String get imageRestoreCupcakePath => currentTheme.type == ThemeType.dark
      ? 'assets/images/restore_cupcake_dark.png'
      : 'assets/images/restore_cupcake.png';

  @override
  Widget? trailing(BuildContext context) => DeviceInfo.instance.isMobile
      ? Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: ModernButton.svg(
            key: ValueKey("restore_options_from_qr_button_key"),
            size: 37,
            svgPath: "assets/new-ui/scan.svg",
            iconSize: 20,
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: S.of(context).scan_qr_code,
            onPressed: () => _onScanQRCode(context),
          ),
        )
      : null;

  @override
  Widget body(BuildContext context) => Center(
        child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 24,
              children: <Widget>[
                if (isNewInstall)
                  _RestoreOptionsHeader(
                    text: S.of(context).restore_options_existing_wallets,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                _RestoreOptionTile(
                  key: ValueKey('restore_options_from_seeds_or_keys_button_key'),
                  onPressed: () => Navigator.pushNamed(context, Routes.restoreWalletFromSeedKeys),
                  image: CakeImageWidget(
                    imageUrl: "assets/new-ui/restore_options/recovery_phrase.svg",
                    width: 55,
                    height: 55,
                  ),
                  title: S.of(context).restore_title_from_seed_keys,
                  description: S.of(context).restore_description_from_seed_keys,
                ),
                if (FeatureFlag.hasBitcoinViewOnly && DeviceInfo.instance.isMobile)
                  _RestoreOptionTile(
                    key: ValueKey('restore_options_from_cupcake_button_key'),
                    onPressed: () => _onScanQRCode(context),
                    image: Image.asset(imageRestoreCupcakePath, width: 55),
                    title: S.of(context).restore_title_from_cupcake,
                    description: S.of(context).restore_description_from_cupcake,
                  ),
                _RestoreOptionTile(
                  key: ValueKey('restore_options_from_hardware_wallet_button_key'),
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.restoreWalletFromHardwareWallet),
                  image: Image.asset(imageRestoreHWPath, width: 55),
                  title: S.of(context).restore_title_from_hardware_wallet,
                  description: S.of(context).restore_description_from_hardware_wallet,
                ),
                if (isNewInstall)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      _RestoreOptionsHeader(
                        text: S.of(context).restore_options_full_app_restore,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      _RestoreOptionTile(
                        key: ValueKey('restore_options_from_backup_button_key'),
                        onPressed: () => backupRestoreFlow.start(context),
                        image: CakeImageWidget(
                          imageUrl: "assets/new-ui/app_backup/backup_file.svg",
                          width: 55,
                          height: 55,
                          fit: BoxFit.contain,
                        ),
                        title: S.of(context).restore_title_from_backup,
                        description: S.of(context).restore_description_from_backup,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );

  void _showQRScanError(BuildContext context, String error) {
    _isScanning.value = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.current.error,
                  alertContent: error,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
      }
    });
  }

  Future<void> _onScanQRCode(BuildContext context) async {
    final isCameraPermissionGranted =
        await PermissionHandler.checkPermission(Permission.camera, context);

    if (!isCameraPermissionGranted) return;
    try {
      if (_isScanning.value) return;

      _isScanning.value = true;

      final restoredWallet = await WalletRestoreFromQRCode.scanQRCodeForRestoring(context);

      final params = {
        'walletType': restoredWallet.type,
        'restoredWallet': restoredWallet,
        'hardwareWalletType': HardwareWalletType.cupcake,
      };

      Navigator.pushNamed(context, Routes.restoreWallet, arguments: params)
          .then((_) => _isScanning.value = false);
    } catch (e) {
      _showQRScanError(context, e.toString());
    }
  }
}

class _RestoreOptionsHeader extends StatelessWidget {
  const _RestoreOptionsHeader({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(text, textAlign: TextAlign.center, style: style),
      );
}

class _RestoreOptionTile extends StatelessWidget {
  const _RestoreOptionTile({
    required this.onPressed,
    required this.image,
    required this.title,
    required this.description,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget image;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              context.customColors.cardGradientColorPrimary,
              context.customColors.cardGradientColorSecondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: EdgeInsets.all(20),
          ),
          onPressed: onPressed,
          child: Row(
            spacing: 20,
            children: [
              SizedBox.square(dimension: 55, child: image),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.headlineSmall),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
