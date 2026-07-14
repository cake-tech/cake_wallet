import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class WalletGroupExistingSeedDescriptionPage extends BasePage {
  WalletGroupExistingSeedDescriptionPage();

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => S.current.wallet_group;

  final walletGroupConfirmedImageLight = 'assets/new-ui/hero/wallet_group_confirmed_light.svg';
  final walletGroupConfirmedImageDark = 'assets/new-ui/hero/wallet_group_confirmed_dark.svg';

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
          CakeImageWidget(
              imageUrl: currentTheme.isDark
                  ? walletGroupConfirmedImageDark
                  : walletGroupConfirmedImageLight,
              height: 200),
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
                        text: S.current.wallet_group_description_view_seed + '\n',
                        style: textStyle),
                    TextSpan(
                      text: S.current.seed_display_path,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: PrimaryButton(
                        key: ValueKey(
                            'wallet_group_existing_seed_description_page_open_wallet_button_key'),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        text: S.current.open_wallet,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
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
