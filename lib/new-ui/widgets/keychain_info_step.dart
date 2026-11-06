import "package:flutter/material.dart";

class KeychainInfoStep extends StatelessWidget {
  const KeychainInfoStep({
    required this.icons,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.centered = false,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final List<Widget> icons;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final bool centered;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        spacing: 12,
        crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(mainAxisSize: MainAxisSize.min, spacing: 16, children: icons),
          Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 12,
              color: titleColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
