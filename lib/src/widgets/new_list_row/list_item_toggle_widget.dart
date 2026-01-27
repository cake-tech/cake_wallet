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
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isFirstInSection;
  final bool isLastInSection;

  @override
  State<ListItemToggleWidget> createState() => _ListItemToggleWidgetState();
}

class _ListItemToggleWidgetState extends State<ListItemToggleWidget> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListItemStyleWrapper(
        isFirstInSection: widget.isFirstInSection,
        isLastInSection: widget.isFirstInSection,
        builder: (context, textStyle, labelStyle) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: textStyle),
              StandardSwitch(
                value: _value,
                onTapped: () {
                  final newValue = !_value;
                  setState(() => _value = newValue);
                  widget.onChanged(newValue);
                },
              ),
            ],
          );
        });
  }
}
