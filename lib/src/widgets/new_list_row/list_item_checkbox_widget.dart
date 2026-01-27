import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_simple_checkbox.dart';
import 'package:flutter/material.dart';

class ListItemCheckboxWidget extends StatefulWidget {
  const ListItemCheckboxWidget({
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
  State<ListItemCheckboxWidget> createState() => _ListItemCheckboxWidgetState();
}

class _ListItemCheckboxWidgetState extends State<ListItemCheckboxWidget> {
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
      isLastInSection: widget.isLastInSection,
      builder: (context, textStyle, labelStyle) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label),
            NewSimpleCheckbox(
              value: _value,
              onChanged: (newValue) {
                setState(() => _value = newValue);
                widget.onChanged(newValue);
              },
            ),
          ],
        );
      },
    );
  }
}
