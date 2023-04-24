import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/view_model/set_up_2fa_viewmodel.dart';

import '../../../palette.dart';
import '../../widgets/standard_list.dart';

class Setup2FAPage extends BasePage {
  Setup2FAPage({required this.setup2FAViewModel});

  final Setup2FAViewModel setup2FAViewModel;

  @override
  String get title => 'Set up Cake 2FA';

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Important note',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.571,
                    color: Palette.darkBlueCraiola,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  ''' Cake 2FA is NOT as secure as cold storage. 2FA protects against basic '''
                  '''types of attacks, such as your friend providing your fingerprint while you are sleeping.\n\n'''
                  '''Cake 2FA does NOT protect against a compromised device by a sophisticated attacker.\n\n'''
                  '''If you lose access to your 2FA codes, YOU WILL LOSE ACCESS TO THIS WALLET.'''
                  ''' You will need to restore your wallet from mnemonic seed. YOU MUST THEREFORE '''
                  '''BACK UP YOUR MNEMONIC SEEDS! Further, someone with access to your mnemonic seed(s) '''
                  '''will be able to steal your funds, bypassing Cake 2FA.\n\n'''
                  '''Cake support staff will be unable to assist you if you lose '''
                  '''access to your mnemonic seed, since Cake is a noncustodial wallet.''',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 1.571,
                    color: Palette.darkBlueCraiola,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 86),
          SettingsCellWithArrow(
            title: 'Set up TOTP(Recommended)',
            handler: (_) => Navigator.of(context).pushNamed(Routes.setup_2faQRPage),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsCellWithArrow(
            title: 'Set up HOTP',
            handler: (_) {},
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
        ],
      ),
    );
  }
}
