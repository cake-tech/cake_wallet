import "package:cake_wallet/entities/spark_exit_quote.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/material.dart";

/// Shows what an exit at the chosen rate would recover and cost, or why it
/// can't be done. A null [quote] means one is still being fetched.
class SparkExitQuoteSummary extends StatelessWidget {
  const SparkExitQuoteSummary({required this.quote, super.key});

  final SparkExitQuote? quote;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;
    final textTheme = Theme.of(context).textTheme;

    if (quote == null) {
      return const Center(
        child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final failureMessage = quote.failureMessage;
    if (failureMessage != null) {
      return Text(
        failureMessage,
        key: const ValueKey("spark_exit_quote_failure_key"),
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
      );
    }

    return Column(
      key: const ValueKey("spark_exit_quote_summary_key"),
      spacing: 4,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).receive_amount, style: textTheme.bodyMedium),
            Text(quote.recoverableAmount!, style: textTheme.bodyMedium),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.of(context).fee, style: textTheme.bodyMedium),
            Text(quote.feeAmount!, style: textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
