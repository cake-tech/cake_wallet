import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/spark_stable_balance_send/spark_stable_balance_send_bloc.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_summary_row.dart";
import "package:cake_wallet/new-ui/widgets/send_page/spark_stable_balance_conversion_details.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";

/// The send page's box while Stable Balance is on: which balance pays, what the recipient gets
/// (over Lightning or as a Spark transfer), and the live conversion quote.
class SparkStableBalanceSendSummary extends StatelessWidget {
  const SparkStableBalanceSendSummary({
    required this.state,
    required this.token,
    required this.tokenBalance,
    required this.maxSlippageBps,
    required this.formatAmount,
    this.recipientLooksOnChain = false,
    super.key,
  });

  final SparkStableBalanceSendState state;
  final CryptoCurrency token;
  final Money? tokenBalance;
  final int maxSlippageBps;
  final String Function(Money amount) formatAmount;

  /// A guess from the address alone, used until a quote says for sure.
  final bool recipientLooksOnChain;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = this.state;
    final quote = state is SparkStableBalanceSendQuoted ? state.quote : null;
    final conversion = quote?.conversion;
    // The SDK only converts when the sats balance can't cover the payment.
    final paysFromSats = quote != null && conversion == null;
    final onChain = quote?.isOnChain ?? recipientLooksOnChain;
    final tokenBalance = this.tokenBalance;
    final smallStyle = TextStyle(fontSize: 12, color: colors.onSurfaceVariant);

    return Container(
      key: const ValueKey("stable_balance_send_summary"),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SendSummaryRow(
            key: const ValueKey("stable_balance_send_paying_from"),
            leading: ExcludeSemantics(
              child: CakeImageWidget(
                imageUrl: (paysFromSats ? CryptoCurrency.btcln : token).iconPath ?? "",
                width: 24,
                height: 24,
              ),
            ),
            label: paysFromSats
                ? S.of(context).stable_balance_send_paying_from_lightning
                : S.of(context).stable_balance_send_paying_from(token.title),
            value: paysFromSats || tokenBalance == null
                ? ""
                : S.of(context).stable_balance_send_available(formatAmount(tokenBalance)),
          ),
          SendSummaryRow(
            key: const ValueKey("stable_balance_send_recipient_gets"),
            leading: ExcludeSemantics(
              child: CakeImageWidget(
                imageUrl: (onChain ? CryptoCurrency.btc : CryptoCurrency.btcln).iconPath ?? "",
                width: 24,
                height: 24,
              ),
            ),
            label: S.of(context).stable_balance_send_recipient_gets,
            value: quote != null
                ? formatAmount(quote.amount)
                : onChain
                    ? S.of(context).stable_balance_send_via_onchain
                    : S.of(context).stable_balance_send_via_lightning,
            emphasized: quote != null,
          ),
          if (state is! SparkStableBalanceSendNotLoaded)
            Divider(height: 1, thickness: 1, color: colors.surfaceContainerHigh),
          if (state is SparkStableBalanceSendQuoting)
            Row(
              key: const ValueKey("stable_balance_send_fetching_rate"),
              spacing: 8,
              children: [
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                Text(S.of(context).stable_balance_send_fetching_rate, style: smallStyle),
              ],
            ),
          if (quote != null && conversion != null) ...[
            SparkStableBalanceConversionDetails(
              conversion: conversion,
              lightningFee: quote.fee,
              formatAmount: formatAmount,
            ),
            Text(
              S.of(context).stable_balance_send_slippage_note(
                    "${(maxSlippageBps / 100).toStringAsFixed(1)}%",
                  ),
              style: smallStyle,
            ),
          ],
          if (quote != null && conversion == null)
            SendSummaryRow(
              key: const ValueKey("stable_balance_send_fees"),
              label: S.of(context).stable_balance_send_fees,
              value: formatAmount(quote.fee),
            ),
          if (state is SparkStableBalanceSendQuoteFailed)
            Column(
              key: const ValueKey("stable_balance_send_quote_failed"),
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: colors.error),
                    Expanded(
                      child: Text(
                        S.of(context).stable_balance_send_quote_failed,
                        style: TextStyle(fontSize: 14, color: colors.error),
                      ),
                    ),
                  ],
                ),
                Text(
                  state.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: smallStyle,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
