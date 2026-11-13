import "package:flutter/material.dart";

class SparkFeeRateChip extends StatelessWidget {
  const SparkFeeRateChip({
    required this.label,
    required this.feeRate,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final int feeRate;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text("$label - $feeRate sat/vB"),
        selected: selected,
        onSelected: (_) => onSelected(),
      );
}
