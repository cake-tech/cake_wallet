import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:flutter/material.dart';

class ListItemTextFieldWidget extends StatefulWidget {
  const ListItemTextFieldWidget({
    super.key,
    required this.keyValue,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.isFirstInSection = false,
    this.isLastInSection = false,
    this.height = 50,
    this.border = InputBorder.none,
    this.focusedBorder = InputBorder.none,
    this.enabledBorder = InputBorder.none,
    this.disabledBorder = InputBorder.none,
    this.suffixIcon,
    this.suffixIconConstraints,
  });

  final String keyValue;
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool isFirstInSection;
  final bool isLastInSection;
  final double height;
  final InputBorder border;
  final InputBorder focusedBorder;
  final InputBorder enabledBorder;
  final InputBorder disabledBorder;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;

  @override
  State<ListItemTextFieldWidget> createState() => _ListItemTextFieldWidgetState();
}

class _ListItemTextFieldWidgetState extends State<ListItemTextFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return ListItemStyleWrapper(
        isFirstInSection: widget.isFirstInSection,
        isLastInSection: widget.isLastInSection,
        height: widget.height,
        builder: (context, textStyle, labelStyle) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  validator: widget.validator,
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onFieldSubmitted,
                  focusNode: widget.focusNode,
                  style: textStyle,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    labelStyle: labelStyle,
                    border: widget.border,
                    focusedBorder: widget.focusedBorder,
                    enabledBorder: widget.enabledBorder,
                    disabledBorder: widget.disabledBorder,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
                    suffixIcon: widget.suffixIcon,
                    suffixIconConstraints: widget.suffixIconConstraints,
                  ),
                ),
              ),
            ],
          );
        });
  }
}
