import 'dart:io';

import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_no_action.dart.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/option_tile.dart';
import 'package:cake_wallet/themes/extensions/option_tile_theme.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/permission_handler.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/restore_from_qr_vm.dart';
import 'package:cake_wallet/view_model/restore/wallet_restore_from_qr_code.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';

class RestoreOptionsPage extends BasePage {
  RestoreOptionsPage({required this.isNewInstall});

  @override
  String get title => S.current.restore_restore_wallet;

  final bool isNewInstall;

  @override
  Widget body(BuildContext context) {
    return _RestoreOptionsBody(isNewInstall: isNewInstall);
  }
}

class _RestoreOptionsBody extends StatefulWidget {
  const _RestoreOptionsBody({required this.isNewInstall});

  final bool isNewInstall;

  @override
  _RestoreOptionsBodyState createState() => _RestoreOptionsBodyState();
}

class _RestoreOptionsBodyState extends State<_RestoreOptionsBody> {
  ReactionDisposer? _reactionDisposer;
  BuildContext? _restoringWalletContext;

  bool get _doesSupportHardwareWallets {
    if (!DeviceInfo.instance.isMobile) {
      return false;
    }

    if (isMoneroOnly) {
      return DeviceConnectionType.supportedConnectionTypes(WalletType.monero, Platform.isIOS).isNotEmpty;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final imageColor = Theme.of(context).extension<OptionTileTheme>()!.titleColor;
    final imageLedger = Image.asset('assets/images/ledger_nano.png', width: 40, color: imageColor);
    final imageSeedKeys = Image.asset('assets/images/restore_wallet_image.png', color: imageColor);
    final imageBackup = Image.asset('assets/images/backup.png', color: imageColor);
    final qrCode = Image.asset('assets/images/restore_qr.png', color: imageColor);

    return Center(
      child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                OptionTile(
                  key: ValueKey('restore_options_from_seeds_button_key'),
                  onPressed: () =>
                      Navigator.pushNamed(
                        context,
                        Routes.restoreWalletFromSeedKeys,
                        arguments: widget.isNewInstall,
                      ),
                  image: imageSeedKeys,
                  title: S.of(context).restore_title_from_seed_keys,
                  description: S.of(context).restore_description_from_seed_keys,
                ),
                if (widget.isNewInstall)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      key: ValueKey('restore_options_from_backup_button_key'),
                      onPressed: () => Navigator.pushNamed(context, Routes.restoreFromBackup),
                      image: imageBackup,
                      title: S.of(context).restore_title_from_backup,
                      description: S.of(context).restore_description_from_backup,
                    ),
                  ),
                if (_doesSupportHardwareWallets)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: OptionTile(
                      key: ValueKey('restore_options_from_hardware_wallet_button_key'),
                      onPressed: () => Navigator.pushNamed(context, Routes.restoreWalletFromHardwareWallet,
                          arguments: widget.isNewInstall),
                      image: imageLedger,
                      title: S.of(context).restore_title_from_hardware_wallet,
                      description: S.of(context).restore_description_from_hardware_wallet,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: OptionTile(
                    key: ValueKey('restore_options_from_qr_button_key'),
                    onPressed: () => _onScanQRCode(context),
                    image: qrCode,
                    title: S.of(context).scan_qr_code,
                    description: S.of(context).cold_or_recover_wallet,
                  ),
                )
              ],
            ),
          )),
    );
  }

  void _onWalletCreateFailure(BuildContext context, String error) {
    if (_restoringWalletContext != null) {
      Navigator.of(_restoringWalletContext!).pop();
      _restoringWalletContext = null;
    }

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

  Future<void> _onScanQRCode(BuildContext context) async {
    final isCameraPermissionGranted = await PermissionHandler.checkPermission(Permission.camera, context);

    if (!isCameraPermissionGranted) return;
    bool isPinSet = false;
    if (widget.isNewInstall) {
      await Navigator.pushNamed(context, Routes.setupPin,
          arguments: (PinCodeState<PinCodeWidget> setupPinContext, String _) {
            setupPinContext.close();
            isPinSet = true;
          });
    }
    if (!widget.isNewInstall || isPinSet) {
      try {
        final restoreWallet = await WalletRestoreFromQRCode.scanQRCodeForRestoring(context);

        final restoreFromQRViewModel = getIt.get<WalletRestorationFromQRVM>(param1: restoreWallet.type);

        _disposePreviousReaction();
        _setEffects(context, restoreFromQRViewModel);

        await restoreFromQRViewModel.create(restoreWallet: restoreWallet);
      } catch (e) {
        _onWalletCreateFailure(context, e.toString());
      }
    }
  }

  void _setEffects(BuildContext context, WalletRestorationFromQRVM restoreFromQRViewModel) {
    _reactionDisposer = reaction((_) => restoreFromQRViewModel.state, (ExecutionState state) async {
      if (state is IsExecutingState) {
        await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              _restoringWalletContext = context;
              return AlertWithNoAction(
                  alertTitle: 'Restoring wallet',
                  alertContent: S.current.please_wait,
                  alertBarrierDismissible: false);
            });
      }

      if (state is FailureState) {
        if (_restoringWalletContext != null && Navigator.canPop(_restoringWalletContext!)) {
          Navigator.of(_restoringWalletContext!).pop();
          _restoringWalletContext = null;
        }

        await Future.delayed(const Duration(milliseconds: 100));

        _onWalletCreateFailure(context, 'Create wallet state: ${(restoreFromQRViewModel.state as FailureState).error}');
      }

      if (state is ExecutedSuccessfullyState) {
        if (_restoringWalletContext != null && Navigator.canPop(_restoringWalletContext!)) {
          Navigator.of(_restoringWalletContext!).pop();
          _restoringWalletContext = null;
        }
      }
    });
  }

  void _disposePreviousReaction() {
    if (_reactionDisposer != null) {
      _reactionDisposer!();
      _reactionDisposer = null;
    }
  }

  @override
  void dispose() {
    _disposePreviousReaction();
    super.dispose();
  }
}