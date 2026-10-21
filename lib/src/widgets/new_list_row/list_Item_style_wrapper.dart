import 'package:flutter/material.dart';

class ListItemStyleWrapper extends StatelessWidget {
  const ListItemStyleWrapper({
    super.key,
    required this.isFirstInSection,
    required this.isLastInSection,
    required this.builder,
    this.backgroundColor,
    this.onTap,
    this.contentPadding,
    this.height,
    this.hasLeading = false,
    this.isDense = false,
  });

  final bool hasLeading;
  final bool isFirstInSection;
  final bool isLastInSection;
  final double? height;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Widget Function(BuildContext context, TextStyle textStyle, TextStyle labelStyle) builder;
  final EdgeInsets? contentPadding;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurface,
      letterSpacing: isDense ? -0.07 : null,
    );

    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurfaceVariant,
    );

    final cardRadius = isDense ? 20.0 : 18.0;
    final radius = BorderRadius.vertical(
      top: Radius.circular(isFirstInSection ? cardRadius : 0),
      bottom: Radius.circular(isLastInSection ? cardRadius : 0),
    );

    return ClipRSuperellipse(
      borderRadius: radius,
      child: Column(
        children: [
          Container(
              height: height,
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: radius,
                ),
                color: backgroundColor ?? theme.colorScheme.surfaceContainer,
              ),
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: onTap,
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: height == null ? 11 : 0),
                          child: builder(context, textStyle, labelStyle))))),
          if (hasLeading && isLastInSection == false)
            Container(
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: isDense
                    ? const EdgeInsets.only(left: 48, right: 12)
                    : const EdgeInsets.only(left: 50, right: 13),
                child: Container(height: 1, color: theme.colorScheme.outlineVariant),
              ),
            )
          else if (!isLastInSection)
            Container(
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(height: 1, color: theme.colorScheme.outlineVariant),
              ),
            )
        ],
      ),
    );
  }
}
