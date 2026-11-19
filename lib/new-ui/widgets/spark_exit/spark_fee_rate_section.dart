import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/spark_exit/spark_fee_rate_chip.dart";
import "package:cw_core/transaction_priority.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

/// Fee rate picker for the Spark exit: one chip per Bitcoin priority plus a custom sat/vB field.
class SparkFeeRateSection extends StatelessWidget {
  const SparkFeeRateSection({
    required this.controller,
    required this.feeRate,
    required this.bitcoinFeeRatePriorities,
    required this.maxFeeRate,
    required this.onFeeRateSelected,
    required this.onFeeRateChanged,
    super.key,
  });

  final TextEditingController controller;

  /// The rate currently typed, or null when it cannot be used.
  final int? feeRate;
  final List<({TransactionPriority priority, int feeRate})> bitcoinFeeRatePriorities;
  final int maxFeeRate;
  final ValueChanged<int> onFeeRateSelected;
  final ValueChanged<String> onFeeRateChanged;

  @override
  Widget build(BuildContext context) => Column(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).fee_rate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < bitcoinFeeRatePriorities.length; i++)
                SparkFeeRateChip(
                  key: ValueKey("spark_unilateral_exit_fee_rate_chip_key_$i"),
                  label: bitcoinFeeRatePriorities[i].priority.toString(),
                  feeRate: bitcoinFeeRatePriorities[i].feeRate,
                  selected: feeRate == bitcoinFeeRatePriorities[i].feeRate,
                  onSelected: () => onFeeRateSelected(bitcoinFeeRatePriorities[i].feeRate),
                ),
            ],
          ),
          TextField(
            key: const ValueKey("spark_unilateral_exit_fee_rate_field_key"),
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onFeeRateChanged,
            decoration: InputDecoration(
              labelText: S.of(context).custom_fee,
              suffixText: "sat/vB",
              errorText: feeRate == null ? "1 - $maxFeeRate" : null,
            ),
          ),
        ],
      );
}
