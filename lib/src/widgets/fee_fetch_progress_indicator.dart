import "package:flutter/material.dart";

/// A small ring progress indicator with a "resolved/total" count in the
/// center.
class FeeFetchProgressIndicator extends StatelessWidget {
  const FeeFetchProgressIndicator({
    required this.resolved,
    required this.total,
    this.diameter = 28,
    super.key,
  });

  final int resolved;
  final int total;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? resolved / total : null;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            color: const Color(0xFFFFB84E),
          ),
          if (total > 0)
            Text(
              "$resolved/$total",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
