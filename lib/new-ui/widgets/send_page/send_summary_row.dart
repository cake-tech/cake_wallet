import "package:flutter/material.dart";

/// A label/value line in the send page's and the confirm sheet's summary boxes.
class SendSummaryRow extends StatelessWidget {
  const SendSummaryRow({
    required this.label,
    required this.value,
    this.leading,
    this.emphasized = false,
    super.key,
  });

  final String label;
  final String value;
  final Widget? leading;

  /// Draws [value] in the primary text color and a heavier weight, for the numbers that matter.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MergeSemantics(
      child: Row(
        spacing: 8,
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, color: colors.onSurface)),
          ),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
              color: emphasized ? colors.onSurface : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
