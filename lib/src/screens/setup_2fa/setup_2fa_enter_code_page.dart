import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/src/screens/setup_2fa/widgets/popup_cancellable_alert.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/view_model/setup_pin_code_view_model.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';

import '../../widgets/primary_button.dart';
import '../../widgets/standard_list.dart';

class Setup2FAEnterCodePage extends BasePage {
  Setup2FAEnterCodePage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

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
            onPressed: () async => await showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return PopUpCancellableAlertDialog(
                    contentText:
                        'Success! Cake 2FA enabled for this wallet. Remember to save your mnemonic seed in case you lose wallet access.',
                    actionButtonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop()
                      );
              },
            ),
            text: S.of(context).continue_text,
            color: Theme.of(context).accentTextTheme!.bodyText1!.color!,
            textColor: Colors.white,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
