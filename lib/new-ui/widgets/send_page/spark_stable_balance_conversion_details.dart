import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_summary_row.dart";
import "package:cw_core/amount/money.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cake_wallet/entities/spark_conversion.dart";
import "package:flutter/material.dart";

/// What a Stable Balance-funded Lightning send costs in the stablecoin: the total, the rate, and
/// the fees.
class SparkStableBalanceConversionDetails extends StatelessWidget {
  const SparkStableBalanceConversionDetails({
    required this.conversion,
    required this.formatAmount,
    this.lightningFee,
    super.key,
  });

  final StableBalanceSendConversion conversion;
  final String Function(Money amount) formatAmount;

  /// Folded into the fees row when given; left out where the Lightning fee has its own row.
  final Money? lightningFee;

  @override
  Widget build(BuildContext context) {
    final satsPerToken = conversion.satsPerWholeToken;
    final lightningFee = this.lightningFee;
    final adjustment = switch (conversion.amountAdjustment) {
      ConversionAmountAdjustment.flooredToMinLimit => S.of(context).conversion_adjustment_min_limit,
      ConversionAmountAdjustment.increasedToAvoidDust =>
        S.of(context).conversion_adjustment_avoid_dust,
      null => null,
    };

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SendSummaryRow(
          key: const ValueKey("stable_balance_send_you_pay"),
          label: S.of(context).stable_balance_send_you_pay,
          value: formatAmount(conversion.amountIn),
          emphasized: true,
        ),
        if (satsPerToken != null)
          SendSummaryRow(
            key: const ValueKey("stable_balance_send_rate"),
            label: S.of(context).stable_balance_send_rate,
            value: "1 ${conversion.amountIn.currency.symbol} ≈ "
                "${formatAmount(Money(satsPerToken, CryptoCurrency.btcln))}",
          ),
        SendSummaryRow(
          key: const ValueKey("stable_balance_send_fees"),
          label: lightningFee == null
              ? S.of(context).stable_balance_send_conversion_fee
              : S.of(context).stable_balance_send_fees,
          value: [
            formatAmount(conversion.fee),
            if (lightningFee != null && lightningFee.amount > BigInt.zero)
              formatAmount(lightningFee),
          ].join(" + "),
        ),
        if (adjustment != null)
          Text(
            adjustment,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
