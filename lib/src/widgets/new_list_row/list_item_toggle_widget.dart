import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:cake_wallet/src/widgets/standard_switch.dart';
import 'package:flutter/material.dart';

class ListItemToggleWidget extends StatefulWidget {
  const ListItemToggleWidget({
    super.key,
    required this.keyValue,
    required this.label,
    required this.value,
    required this.onChanged,
    this.leadingEndWidget,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leadingEndWidget;
  final bool isFirstInSection;
  final bool isLastInSection;

  @override
  State<ListItemToggleWidget> createState() => _ListItemToggleWidgetState();
}

class _ListItemToggleWidgetState extends State<ListItemToggleWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListItemStyleWrapper(
        isFirstInSection: widget.isFirstInSection,
        isLastInSection: widget.isLastInSection,
        onTap: () {
          widget.onChanged(!widget.value);
        },
        builder: (context, textStyle, labelStyle) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  spacing: 8,
                  children: [
                    Flexible(
                      child: Text(widget.label, style: textStyle, softWrap: true),
                    ),
                    if(widget.leadingEndWidget != null) widget.leadingEndWidget!
                  ],
                ),
              ),
              StandardSwitch(
                value: widget.value,
                onTapped: () {
                  widget.onChanged(!widget.value);
                },
              ),
            ],
          );
        });
  }
}
