import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/language_list.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/restore/restore_from_qr_vm.dart';
import 'package:cake_wallet/view_model/restore/wallet_restore_from_qr_code.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/restore/widgets/restore_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';

class RestoreOptionsPage extends BasePage {
  RestoreOptionsPage({required this.isNewInstall});

  @override
  String get title => S.current.restore_restore_wallet;


  final bool isNewInstall;
  final imageSeedKeys = Image.asset('assets/images/restore_wallet_image.png');
  final imageBackup = Image.asset('assets/images/backup.png');
  final qrCode = Image.asset('assets/images/qr_code_icon.png');

  @override
  Widget body(BuildContext context) {
    return Center(
      child: Container(
          width: ResponsiveLayoutUtil.kDesktopMaxWidthConstraint,
          height: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                RestoreButton(
                    onPressed: () => Navigator.pushNamed(
                        context, Routes.restoreWalletFromSeedKeys,
                        arguments: isNewInstall),
                    image: imageSeedKeys,
                    title: S.of(context).restore_title_from_seed_keys,
                    description: S.of(context).restore_description_from_seed_keys),
                if (isNewInstall)
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: RestoreButton(
                        onPressed: () => Navigator.pushNamed(context, Routes.restoreFromBackup),
                        image: imageBackup,
                        title: S.of(context).restore_title_from_backup,
                        description: S.of(context).restore_description_from_backup),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: RestoreButton(
                      onPressed: () async {
                        bool isPinSet = false;
                        if (isNewInstall) {
                          await Navigator.pushNamed(context, Routes.setupPin,
                              arguments: (PinCodeState<PinCodeWidget> setupPinContext, String _) {
                            setupPinContext.close();
                            isPinSet = true;
                          });
                        }
                        if (!isNewInstall || isPinSet) {
                          try {
                            final restoreWallet =
                                await WalletRestoreFromQRCode.scanQRCodeForRestoring(context);

                            final restoreFromQRViewModel = getIt.get<WalletRestorationFromQRVM>(param1: restoreWallet.type);

                            await restoreFromQRViewModel.create(restoreWallet: restoreWallet);
                            if (restoreFromQRViewModel.state is FailureState) {
                              _onWalletCreateFailure(context,
                                  'Create wallet state: ${restoreFromQRViewModel.state.runtimeType.toString()}');
                            }
                          } catch (e) {
                            _onWalletCreateFailure(context, e.toString());
                          }
                        }
                      },
                      image: qrCode,
                      title: S.of(context).scan_qr_code,
                      description: S.of(context).cold_or_recover_wallet),
                )
              ],
            ),
          )),
    );
  }

  void _onWalletCreateFailure(BuildContext context, String error) {
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
}
