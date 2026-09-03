import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart";
import "package:flutter/material.dart";


class ListItemExpansionTileWidget extends StatefulWidget {
  const ListItemExpansionTileWidget({
    required this.keyValue, required this.label, required this.isExpanded, required this.onExpansionChanged, required this.children, super.key,
    this.subtitle,
    this.trailingText,
    this.iconPath,
    this.leadingWidget,
    this.foregroundColor,
    this.onTap,
    this.trailingWidget,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final Widget? leadingWidget;

  final Color? foregroundColor;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback? onTap;
  final Widget? trailingWidget;
  final bool isFirstInSection;
  final bool isLastInSection;
  final List<Widget> children;

  @override
  State<ListItemExpansionTileWidget> createState() => _ListItemExpansionTileWidgetState();
}

class _ListItemExpansionTileWidgetState extends State<ListItemExpansionTileWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLeading = widget.iconPath != null || widget.leadingWidget != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListItemStyleWrapper(
          iconPath: widget.iconPath ?? (hasLeading ? '' : null),
          onTap: widget.onTap ?? () => widget.onExpansionChanged(!widget.isExpanded),
          isFirstInSection: widget.isFirstInSection,
          isLastInSection: widget.isLastInSection && !widget.isExpanded,
          builder: (context, textStyle, labelStyle) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (widget.leadingWidget != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: widget.leadingWidget!,
                        )
                      else if (widget.iconPath != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child:
                          CakeImageWidget(imageUrl: widget.iconPath!, width: 24, height: 24),
                        ),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: widget.foregroundColor == null
                                  ? textStyle
                                  : textStyle.copyWith(color: widget.foregroundColor),
                            ),
                            if (widget.subtitle != null)
                              Text(widget.subtitle!, style: labelStyle.copyWith(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (widget.trailingText != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(widget.trailingText!, style: labelStyle),
                      ),
                    if (widget.trailingWidget != null)
                      widget.trailingWidget!
                    else
                      AnimatedRotation(
                        turns: widget.isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          sizeCurve: Curves.easeInOut,
          crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Column(mainAxisSize: MainAxisSize.min, children: widget.children),
        ),
      ],
    );
  }
}