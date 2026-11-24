import "package:cake_wallet/entities/spark_exit_quote.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/material.dart";

/// The leaves an exit can recover, each one ticked to include it, and the ones it leaves out
/// with the reason why.
class SparkExitLeafPicker extends StatelessWidget {
  const SparkExitLeafPicker({
    required this.leaves,
    required this.selectedLeafIds,
    required this.skipped,
    required this.onLeafToggled,
    super.key,
  });

  final List<SparkExitLeaf> leaves;

  /// The chosen leaves; null when all of them are.
  final Set<String>? selectedLeafIds;
  final List<SparkExitSkippedLeaf> skipped;
  final ValueChanged<String> onLeafToggled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      key: const ValueKey("spark_exit_leaf_picker_key"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leaves.isNotEmpty)
          Text(
            S.of(context).spark_exit_leaves_title,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        for (final leaf in leaves)
          CheckboxListTile(
            key: ValueKey("spark_exit_leaf_${leaf.id}_key"),
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: selectedLeafIds?.contains(leaf.id) ?? true,
            onChanged: (_) => onLeafToggled(leaf.id),
            title: Text(leaf.amount, style: textTheme.bodyMedium),
            subtitle: leaf.isCooperative
                ? Text(S.of(context).spark_exit_leaf_cooperative, style: textTheme.bodySmall)
                : null,
          ),
        if (skipped.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            S.of(context).spark_exit_skipped_title,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          for (final leaf in skipped)
            ListTile(
              key: ValueKey("spark_exit_skipped_leaf_${leaf.id}_key"),
              contentPadding: EdgeInsets.zero,
              dense: true,
              enabled: false,
              title: Text(leaf.amount, style: textTheme.bodyMedium?.copyWith(color: mutedColor)),
              subtitle: Text(leaf.reason, style: textTheme.bodySmall?.copyWith(color: mutedColor)),
            ),
        ],
      ],
    );
  }
}
