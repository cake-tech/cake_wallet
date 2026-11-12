import "package:cake_wallet/generated/i18n.dart";
import "package:flutter/material.dart";

/// Shown while the Spark balance is merged into fewer, larger leaves before the exit is quoted.
class SparkExitMergingLeaves extends StatelessWidget {
  const SparkExitMergingLeaves({super.key});

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey("spark_exit_merging_leaves_key"),
        spacing: 8,
        children: [
          const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          Text(
            S.of(context).spark_exit_merging_leaves,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
}
