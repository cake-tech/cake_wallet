import 'package:flutter/material.dart';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/totp_utils.dart' as Utils;
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';

class Setup2FAEnterCodePage extends BasePage {
  Setup2FAEnterCodePage({required this.setup2FAViewModel})
      : totpController = TextEditingController();

  final Setup2FAViewModel setup2FAViewModel;
  final TextEditingController totpController;
  @override
  String get title => 'Set up Cake 2FA';

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
            textAlign: TextAlign.center,
          ),
          Spacer(),
          PrimaryButton(
            onPressed: () async {
              await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return PopUpCancellableAlertDialog(
                    contentText:
                        () {
                      final code = Utils.totpNow(setup2FAViewModel.secretKey);

                      switch (code == totpController.text) {
                        case true:
                          return 'Success! Cake 2FA enabled for this wallet. Remember to save your mnemonic seed in case you lose wallet access.';
                        case false:
                          return 'Incorrect code. Please try a different code or generate a new secret key.';
                        default:
                          return 'Please enter the TOTP Code.';
                      }
                    }(),
                    actionButtonText: S.of(context).ok,
                    buttonAction: () {
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
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
