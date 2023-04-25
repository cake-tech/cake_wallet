import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class Modify2FAPage extends BasePage {
  Modify2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => 'Modify Cake 2FA';

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsCellWithArrow(
              title: 'Disable Cake 2FA',
              handler: (_) async {
                await showPopUp<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertWithTwoActions(
                      alertTitle: 'Disable Cake 2FA',
                      alertContent:
                          'Are you sure that you want to disable Cake 2FA? A 2FA code will no longer be needed to access the wallet and certain functions.',
                      leftButtonText: 'Cancel',
                      rightButtonText: 'Disable',
                      actionLeftButton: () {
                        Navigator.of(context).pop();
                      },
                      actionRightButton: () {
                        setup2FAViewModel.setUseTOTP2FA(false);
                        setup2FAViewModel.clearBase32SecretKey();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              }),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        ],
      ),
    );
  }
}
