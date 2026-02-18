import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListItemCheckboxWidget extends StatefulWidget {
  const ListItemCheckboxWidget({
    super.key,
    required this.keyValue,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onTap,
    this.isFirstInSection = false,
    this.isLastInSection = false, this.subtitle, this.iconPath, this.showArrow = false,
  });

  final String keyValue;
  final String label;
  final String? subtitle;
  final String? iconPath;
  final bool showArrow;
  final bool value;
  final VoidCallback? onTap;
  final ValueChanged<bool> onChanged;
  final bool isFirstInSection;
  final bool isLastInSection;

  @override
  State<ListItemCheckboxWidget> createState() => _ListItemCheckboxWidgetState();
}

class _ListItemCheckboxWidgetState extends State<ListItemCheckboxWidget> {


  @override
  Widget build(BuildContext context) {
    return ListItemStyleWrapper(
      onTap: widget.onTap ?? () {
        widget.onChanged(!widget.value);
      },
      isFirstInSection: widget.isFirstInSection,
      height: widget.subtitle != null ? 64 : 50,
      isLastInSection: widget.isLastInSection,
      builder: (context, textStyle, labelStyle) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 12,
              children: [
                if (widget.iconPath != null)
                  widget.iconPath!.toLowerCase().endsWith("svg")
                      ? SvgPicture.asset(widget.iconPath!, height: 24, width: 24)
                      : Image.asset(
                          widget.iconPath!,
                          width: 24,
                          height: 24,
                        ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(widget.label),
                        if (widget.showArrow)
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                      ],
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                            fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      )
                  ],
                ),
              ],
            ),
            NewSimpleCheckbox(
              value: widget.value,
              onChanged: (newValue) {
                widget.onChanged(newValue);
              },
            ),
          ],
        );
      },
    );
  }
}
