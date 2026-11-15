import "dart:math";

import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/token_image_widget.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart";
import "package:cake_wallet/src/widgets/standard_switch.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class TokenListSection extends StatelessWidget {
  const TokenListSection({
    required this.viewModel,
    required this.tokens,
    super.key,
    this.title,
    this.onSeeAll,
    this.footer,
  });

  final HomeSettingsViewModel viewModel;
  final List<CryptoCurrency> tokens;
  final String? title;
  final VoidCallback? onSeeAll;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, bottom: 12),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          for (final (index, token) in tokens.indexed)
            _TokenRow(
              key: ValueKey(viewModel.getTokenAddressBasedOnWallet(token)),
              viewModel: viewModel,
              token: token,
              isFirstInSection: index == 0,
              isLastInSection: index == tokens.length - 1 && onSeeAll == null,
            ),
          if (onSeeAll != null)
            ListItemRegularRowWidget(
              keyValue: "see_all",
              label: S.of(context).picker_see_all,
              foregroundColor: Theme.of(context).colorScheme.primary,
              isLastInSection: true,
              onTap: onSeeAll,
            ),
          if (footer != null) Padding(padding: const EdgeInsets.only(top: 12), child: footer),
        ],
      );
}

class FlaggedTokensNote extends StatelessWidget {
  const FlaggedTokensNote({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        spacing: 10,
        children: [
          CakeImageWidget(
            imageUrl: "assets/new-ui/warning.svg",
            width: 16,
            height: 16,
            color: color,
          ),
          Expanded(
            child: Text(
              S.of(context).flagged_tokens_hidden,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.viewModel,
    required this.token,
    required this.isFirstInSection,
    required this.isLastInSection,
    super.key,
  });

  final HomeSettingsViewModel viewModel;
  final CryptoCurrency token;
  final bool isFirstInSection;
  final bool isLastInSection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListItemStyleWrapper(
      isFirstInSection: isFirstInSection,
      isLastInSection: isLastInSection,
      iconPath: token.iconPath ?? "",
      onTap: () => Navigator.pushNamed(
        context,
        Routes.editToken,
        arguments: {"homeSettingsViewModel": viewModel, "token": token},
      ),
      builder: (context, textStyle, labelStyle) => Observer(
        builder: (_) => Row(
          spacing: 12,
          children: [
            TokenImageWidget(
              imageUrl: token.iconPath ?? "",
              size: 32,
              errorWidget: Text(
                token.title.substring(0, min(token.title.length, 2)),
                style: labelStyle.copyWith(fontSize: 11),
              ),
            ),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      Flexible(
                        child: Text(
                          token.fullName ?? token.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: token.isPotentialScam
                              ? textStyle.copyWith(color: colorScheme.onSurfaceVariant)
                              : textStyle,
                        ),
                      ),
                      if (token.isPotentialScam)
                        CakeImageWidget(
                          imageUrl: "assets/new-ui/warning.svg",
                          width: 16,
                          height: 16,
                          color: context.customColors.warningOutlineColor,
                          semanticsLabel: S.of(context).potential_scam,
                        )
                      else if (viewModel.isVerified(token))
                        CakeImageWidget(
                          imageUrl: "assets/new-ui/verified.svg",
                          width: 16,
                          height: 16,
                          color: colorScheme.onSurfaceVariant,
                          semanticsLabel: S.of(context).wc_verified,
                        ),
                    ],
                  ),
                  DefaultTextStyle(
                    style: labelStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: switch (viewModel.heldBalance(token)) {
                      final balance? => MoneyText(balance),
                      null => Text(token.title),
                    },
                  ),
                ],
              ),
            ),
            StandardSwitch(
              value: token.enabled,
              onTapped: () => viewModel.changeTokenAvailability(token, !token.enabled),
            ),
          ],
        ),
      ),
    );
  }
}
