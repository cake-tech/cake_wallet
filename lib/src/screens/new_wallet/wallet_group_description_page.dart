import 'package:cake_wallet/core/new_wallet_arguments.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class WalletGroupDescriptionPage extends BasePage {
  WalletGroupDescriptionPage({required this.selectedWalletType});

  final WalletType selectedWalletType;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
          (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  String get title => S.current.wallet_group;

  @override
  Widget body(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 48),
          CakeImageWidget(
            imageUrl: currentTheme.isDark
                ? 'assets/images/wallet_group_options_dark.png'
                : 'assets/images/wallet_group_options_light.png',
            height: 200,
          ),
          SizedBox(height: 40),
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${S.of(context).wallet_group_description_one} '),
                      TextSpan(
                        text: '${S.of(context).wallet_group.toLowerCase()} ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: '${S.of(context).wallet_group_description_two} ',
                      ),
                      TextSpan(
                        text: '${S.of(context).choose_wallet_group} ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: '${S.of(context).wallet_group_description_three} ',
                      ),
                      TextSpan(
                        text: '${S.of(context).create_new_seed} ',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: S.of(context).wallet_group_description_four),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        height: 1.5,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
          PrimaryButton(
            key: ValueKey('wallet_group_description_page_create_new_seed_button_key'),
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.newWallet,
              arguments: NewWalletArguments(type: selectedWalletType),
            ),
            text: S.of(context).create_new_seed,
            color: Theme.of(context).colorScheme.surfaceContainer,
            textColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          SizedBox(height: 12),
          PrimaryButton(
            key: ValueKey('wallet_group_description_page_choose_wallet_group_button_key'),
            onPressed: () => Navigator.of(context).pushNamed(
              Routes.walletGroupsDisplayPage,
              arguments: selectedWalletType,
            ),
            text: S.of(context).choose_wallet_group,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
