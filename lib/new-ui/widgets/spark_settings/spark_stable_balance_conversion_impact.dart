import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/view_model/dashboard/home_settings_view_model.dart";
import "package:flutter/material.dart";

/// The bold "this is what converts right now" line in the Stable Balance on/off confirmations,
/// plus (when activating) the balance auto-conversion will wait for from then on.
class SparkStableBalanceConversionImpact extends StatelessWidget {
  const SparkStableBalanceConversionImpact({
    required this.preview,
    required this.activating,
    required this.tokenLabel,
    super.key,
    this.fallbackThresholdText,
  });

  final Future<StableBalanceConversionPreview> preview;
  final bool activating;
  final String tokenLabel;

  /// Shown instead of the effective threshold when the limits couldn't be fetched.
  final String? fallbackThresholdText;

  String? _impactText(StableBalanceConversionPreview p) {
    final s = S.current;
    switch (p.outcome) {
      case StableBalanceConversionOutcome.willConvert:
        if (activating) return s.stable_balance_convert_now(p.amount!, p.estimate!, tokenLabel);
        return p.estimate == null
            ? s.stable_balance_deactivate_convert_back_no_estimate(p.amount!)
            : s.stable_balance_deactivate_convert_back(p.amount!, p.estimate!);
      case StableBalanceConversionOutcome.belowMinimum:
        return activating
            ? s.stable_balance_convert_below_minimum(p.amount!, p.minimum!)
            : s.stable_balance_deactivate_below_minimum(p.amount!, p.minimum!, tokenLabel);
      case StableBalanceConversionOutcome.nothingToConvert:
        return activating
            ? s.stable_balance_convert_nothing
            : s.stable_balance_deactivate_nothing(tokenLabel);
      case StableBalanceConversionOutcome.unknown:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontSize: 14, decoration: TextDecoration.none);

    return FutureBuilder<StableBalanceConversionPreview>(
      future: preview,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              S.of(context).stable_balance_checking_balance,
              textAlign: TextAlign.center,
              style: baseStyle,
            ),
          );
        }

        final result = snapshot.data ?? StableBalanceConversionPreview.unknown;
        final impact = _impactText(result);
        final threshold = result.effectiveThreshold != null
            ? S.of(context).stable_balance_confirm_threshold(result.effectiveThreshold!)
            : fallbackThresholdText;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (impact != null) ...[
              const SizedBox(height: 12),
              Text(
                impact,
                key: const ValueKey("stable_balance_conversion_impact_text"),
                textAlign: TextAlign.center,
                style: baseStyle?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
            if (activating && threshold != null) ...[
              const SizedBox(height: 8),
              Text(threshold, textAlign: TextAlign.center, style: baseStyle),
            ],
          ],
        );
      },
    );
  }
}
