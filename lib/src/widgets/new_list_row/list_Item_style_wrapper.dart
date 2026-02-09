import 'package:flutter/material.dart';

class ListItemStyleWrapper extends StatelessWidget {
  const ListItemStyleWrapper({
    super.key,
    required this.isFirstInSection,
    required this.isLastInSection,
    required this.builder,
    this.hasImage,
    this.onTap,
    this.height = 50,
  });

  final bool isFirstInSection;
  final bool isLastInSection;
  final bool ?hasImage;
  final double height;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, TextStyle textStyle, TextStyle labelStyle) builder;

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
      top: Radius.circular(isFirstInSection ? 18 : 0),
      bottom: Radius.circular(isLastInSection ? 18 : 0),
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
                  color: theme.colorScheme.surfaceContainer,
                ),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: onTap,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: builder(context, textStyle, labelStyle))))),
            if(hasImage == true && isLastInSection == false) Container(
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.only(left: 48, right: 13),
                child: Container(height: 1, color: theme.colorScheme.outlineVariant),
              ),
            )
            else if(!isLastInSection) Container(
              color: theme.colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Container(height: 1, color: theme.colorScheme.outlineVariant),
              ),
            )
          ],
            ),
      );
  }
}
