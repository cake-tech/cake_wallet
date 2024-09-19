import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class WalletGroupDescriptionPage extends BasePage {
  WalletGroupDescriptionPage({required this.selectedWalletType});

  final WalletType selectedWalletType;

  @override
  String get title => S.current.wallet_group;

  @override
  Widget body(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Image.asset(
            'assets/images/wallet_group.png',
            scale: 0.8,
          ),
          SizedBox(height: 32),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'In Cake Wallet, you can create a '),
                  TextSpan(text: 'wallet group ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                    text:
                        'by selecting an existing wallet to share a seed with. Each wallet group can contain a single wallet of each currency type.\n\nYou can select ',
                  ),
                  TextSpan(text: 'Choose Wallet ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(
                    text: 'to see the available wallets and/or wallet groups screen. Or choose ',
                  ),
                  TextSpan(text: 'New Seed ', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: 'to create a wallet with an entirely new seed.'),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
              ),
            ),
          ),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.newWallet,
              arguments: NewWalletArguments(type: selectedWalletType),
            ),
            text: S.of(context).newSeed,
            color: Theme.of(context).cardColor,
            textColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
          ),
          SizedBox(height: 12),
          PrimaryButton(
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.walletGroupsDisplayPage,
              arguments: selectedWalletType,
            ),
            text: 'Choose Wallet',
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
