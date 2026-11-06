import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/defi/defi_earned_text.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart";

ListItemRegularRow defiProviderRow(
  BuildContext context, {
  required String name,
  required Uri website,
}) =>
    ListItemRegularRow(
      keyValue: "defi_provider",
      label: S.of(context).provider,
      trailingText: name,
      trailingWidget: Semantics(
        label: S.of(context).opens_in_browser,
        excludeSemantics: true,
        child: CakeImageWidget(
          imageUrl: "assets/new-ui/external_link.svg",
          width: 16,
          height: 16,
          colorFilter:
              ColorFilter.mode(Theme.of(context).colorScheme.onSurfaceVariant, BlendMode.srcIn),
        ),
      ),
      onTap: () => launchUrl(website, mode: LaunchMode.externalApplication),
    );

ListItemRegularRow defiYieldRow(BuildContext context, String rate, {bool approximate = false}) =>
    defiTextRow(
      context,
      keyValue: "defi_yield",
      label: S.of(context).staking_yield,
      value: "${approximate ? "~" : ""}$rate",
    );

ListItemRegularRow defiTextRow(
  BuildContext context, {
  required String keyValue,
  required String label,
  required String value,
  String? copyableText,
}) =>
    ListItemRegularRow(
      keyValue: keyValue,
      label: label,
      copyableText: copyableText,
      showArrow: false,
      truncateLabel: true,
      trailingWidget: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: _trailingStyle(context),
        ),
      ),
    );

ListItemRegularRow defiEarnedRow(
  BuildContext context,
  Money earned,
  ExchangeRate? fiatRate, {
  bool? isHiddenAmount,
}) =>
    ListItemRegularRow(
      keyValue: "defi_earned",
      label: S.of(context).earned,
      showArrow: false,
      trailingWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 4,
        children: [
          DefiEarnedText(
            earned,
            fiatRate: fiatRate,
            isHiddenAmount: isHiddenAmount,
            style: TextStyle(fontSize: fiatRate == null ? 14 : 12),
          ),
          if (fiatRate != null)
            MoneyText(
              earned,
              isHiddenAmount: isHiddenAmount,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

ListItemRegularRow defiAmountRow(
  BuildContext context, {
  required String keyValue,
  required String label,
  required Money amount,
  bool? isHiddenAmount,
  bool isLoading = false,
  Color? labelColor,
  VoidCallback? onTap,
}) =>
    ListItemRegularRow(
      keyValue: keyValue,
      label: label,
      foregroundColor: labelColor,
      onTap: onTap,
      showArrow: false,
      truncateLabel: true,
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (isLoading)
            const CupertinoActivityIndicator()
          else
            MoneyText(amount, isHiddenAmount: isHiddenAmount, style: _trailingStyle(context)),
          if (onTap != null)
            CakeImageWidget(
              imageUrl: "assets/new-ui/arrow_forward.svg",
              height: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );

ListItemRegularRow defiNetworkFeeRow(BuildContext context, Money fee, ExchangeRate? fiatRate) {
  final fiat = fiatRate?.convert(fee);
  final style = _trailingStyle(context);

  return ListItemRegularRow(
    keyValue: "defi_network_fee",
    label: S.of(context).fee,
    showArrow: false,
    trailingWidget: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MoneyText(fee, isHiddenAmount: false, style: style),
        if (fiat != null)
          MoneyText(
            fiat,
            fractionalDigits: 2,
            trimZeros: false,
            isHiddenAmount: false,
            style: style.copyWith(fontSize: 12),
          ),
      ],
    ),
  );
}

String defiPercentText(BuildContext context, double fraction) {
  final locale = Intl.verifiedLocale(
    Localizations.localeOf(context).toString(),
    NumberFormat.localeExists,
    onFailure: (_) => "en",
  );
  return (NumberFormat.percentPattern(locale)..maximumFractionDigits = 2).format(fraction);
}

TextStyle _trailingStyle(BuildContext context) => TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: "Wix Madefor Text",
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
