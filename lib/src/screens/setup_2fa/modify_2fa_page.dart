import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

import '../../../routes.dart';

class Modify2FAPage extends BasePage {
  Modify2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => S.current.modify_2fa;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsCellWithArrow(
              title: S.current.disable_cake_2fa,
              handler: (_) async {
                await showPopUp<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertWithTwoActions(
                      alertTitle: S.current.disable_cake_2fa,
                      alertContent: S.current.question_to_disable_2fa,
                      leftButtonText: S.current.cancel,
                      rightButtonText: S.current.disable,
                      actionLeftButton: () {
                        Navigator.of(context).pop();
                      },
                      actionRightButton: () {
                        setup2FAViewModel.setUseTOTP2FA(false);
                        Navigator.pushNamedAndRemoveUntil(
                            context, Routes.dashboard, (route) => false);
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
