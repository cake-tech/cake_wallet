import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_earned_text.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_rows.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";

ListItemRegularRow morphoProviderRow(BuildContext context) =>
    defiProviderRow(context, name: "Morpho", website: Uri.https("morpho.org"));

String morphoApyText(BuildContext context, double apy) =>
    S.of(context).percent_apy(defiPercentText(context, apy));

ListItemRegularRow morphoVariableYieldRow(
  BuildContext context, {
  required VoidCallback onTap,
  String? subtitle,
}) =>
    ListItemRegularRow(
      keyValue: "defi_yield",
      label: S.of(context).staking_yield,
      subtitle: subtitle,
      trailingText: S.of(context).variable,
      trailingWidget: CakeImageWidget(
        imageUrl: "assets/new-ui/info_outline.svg",
        width: 24,
        height: 24,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap,
    );

ListItemRegularRow morphoUsdcRow({
  String? trailingText,
  Widget? trailingWidget,
  VoidCallback? onTap,
}) {
  final usdc = MorphoVault.usdcToken;

  return ListItemRegularRow(
    keyValue: "morpho_usdc",
    label: usdc.fullName ?? usdc.title,
    subtitle: usdc.title,
    iconPath: usdc.iconPath,
    trailingText: trailingText,
    trailingWidget: trailingWidget,
    showArrow: false,
    onTap: onTap,
  );
}

ListItemRegularRow morphoTotalEarnedRow(
  BuildContext context,
  Money earned,
  ExchangeRate? fiatRate,
) =>
    ListItemRegularRow(
      keyValue: "morpho_total_earned",
      label: S.of(context).earned,
      showArrow: false,
      trailingWidget:
          DefiEarnedText(earned, fiatRate: fiatRate, style: const TextStyle(fontSize: 14)),
    );

ListItemRegularRow morphoUsdcEarnedRow(
  BuildContext context,
  Money earned,
  ExchangeRate? fiatRate,
) {
  final fiat = fiatRate?.convert(earned);
  final style = TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant);

  return ListItemRegularRow(
    keyValue: "morpho_usdc_earned",
    label: S.of(context).earned,
    showArrow: false,
    trailingWidget: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MoneyText(earned, style: style),
        if (fiat != null) ...[
          Text(" (", style: style),
          MoneyText(fiat, fractionalDigits: 2, trimZeros: false, style: style),
          Text(")", style: style),
        ],
      ],
    ),
  );
}
