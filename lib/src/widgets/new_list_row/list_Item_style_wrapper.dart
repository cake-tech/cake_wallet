import 'package:flutter/material.dart';

class ListItemStyleWrapper extends StatelessWidget {
  const ListItemStyleWrapper({
    super.key,
    required this.isFirstInSection,
    required this.isLastInSection,
    required this.builder,
    this.height = 48,
  });

  final bool isFirstInSection;
  final bool isLastInSection;
  final double height;
  final Widget Function(
      BuildContext context, TextStyle textStyle, TextStyle labelStyle) builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurface,
    );

    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurfaceVariant,
    );

    final radius = BorderRadius.vertical(
      top: Radius.circular(isFirstInSection ? 16 : 0),
      bottom: Radius.circular(isLastInSection ? 16 : 0),
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: isLastInSection
                ? null
                : Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.surfaceContainerHigh,
                    ),
                  ),
          ),
          child: builder(context, textStyle, labelStyle)),
    );
  }
}
