import 'package:flutter/material.dart';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/totp_utils.dart' as Utils;
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';

import '../../../palette.dart';

class Setup2FAEnterCodePage extends BasePage {
  Setup2FAEnterCodePage({required this.setup2FAViewModel, required this.isForSetup})
      : totpController = TextEditingController();

  final Setup2FAViewModel setup2FAViewModel;
  final TextEditingController totpController;
  final bool isForSetup;
  @override
  String get title => isForSetup ? 'Set up Cake 2FA' : 'Verify with Cake 2FA';



  @override
  Widget body(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Column(
        children: [
          BaseTextFormField(
            textAlign: TextAlign.left,
            hintText: 'TOTP Code',
            controller: totpController,
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
            placeholderTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Please fill in the 6-digit code present on your other device',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: Palette.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          Spacer(),
          PrimaryButton(
            onPressed: () async {
              final result = Utils.verify(
                secretKey: setup2FAViewModel.secretKey,
                otp: totpController.text,
              );
              await showPopUp<void>(
                context: context,
                builder: (BuildContext context) {
                  return PopUpCancellableAlertDialog(
                    contentText: () {
                      switch (result) {
                        case true:
                          return isForSetup
                              ? 'Success! Cake 2FA enabled for this wallet. Remember to save your mnemonic seed in case you lose wallet access.'
                              : 'Verification Successful!';
                        case false:
                          return 'Incorrect code. Please try a different code or generate a new secret key.';
                        default:
                          return 'Please enter the TOTP Code.';
                      }
                    }(),
                    actionButtonText: S.of(context).ok,
                    buttonAction: () {
                      isForSetup ? setup2FAViewModel.setUseTOTP2FA(result) : null;
                      Navigator.of(context).pop(result);
                    },
                  );
                },
              ).then((value) => Navigator.of(context).pop(result));
            },
            text: S.of(context).continue_text,
            color: Theme.of(context).accentTextTheme.bodyLarge!.color!,
            textColor: Colors.white,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
