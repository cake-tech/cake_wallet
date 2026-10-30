import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart";
import "package:flutter/material.dart";

class DefiProviderTile extends StatelessWidget {
  const DefiProviderTile({
    required this.logo,
    required this.name,
    required this.trailing,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final Widget logo;
  final String name;
  final Widget Function(TextStyle style) trailing;
  final Widget Function(TextStyle style)? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: Semantics(
          button: onTap != null,
          child: ListItemStyleWrapper(
            isFirstInSection: true,
            isLastInSection: true,
            onTap: onTap,
            builder: (context, textStyle, labelStyle) => Row(
              spacing: 12,
              children: [
                logo,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Text(name, style: textStyle),
                      if (subtitle != null) subtitle!(labelStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                trailing(labelStyle),
                if (onTap != null)
                  CakeImageWidget(
                    imageUrl: "assets/new-ui/arrow_forward.svg",
                    height: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      );
}
