import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/theme_type_images.dart';
import 'package:flutter/material.dart';

class WalletGroupExistingSeedDescriptionPage extends BasePage {
  WalletGroupExistingSeedDescriptionPage();

  @override
  String get title => S.current.wallet_group;

  @override
  Widget body(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Image.asset(currentTheme.type.walletGroupImage, height: 200),
          SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: S.current.wallet_group_description_existing_seed + '\n\n',
                        style: textStyle),
                    TextSpan(
                        text: S.current.wallet_group_description_open_wallet + '\n\n',
                        style: textStyle),
                    TextSpan(
                        text: S.current.wallet_group_description_view_seed + '\n', style: textStyle),
                    TextSpan(
                      text: S.current.seed_display_path,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: PrimaryButton(
                        key: ValueKey(
                            'wallet_group_existing_seed_description_page_verify_seed_button_key'),
                        onPressed: () => Navigator.pushNamed(context, Routes.preSeedPage),
                        text: S.current.verify_seed,
                        color: Theme.of(context).cardColor,
                        textColor: currentTheme.type == ThemeType.dark
                            ? Theme.of(context).colorScheme.surface
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Builder(
                        builder: (context) => PrimaryButton(
                          key: ValueKey(
                              'wallet_group_existing_seed_description_page_open_wallet_button_key'),
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          text: S.current.open_wallet,
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 12),
            ],
          )
        ],
      ),
    );
  }
}
