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

  @override
  State<ListItemTextFieldWidget> createState() =>
      _ListItemTextFieldWidgetState();
}

class _ListItemTextFieldWidgetState extends State<ListItemTextFieldWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final underline = widget.isLastInSection
        ? InputBorder.none
        : UnderlineInputBorder(
            borderSide: BorderSide(
              color: theme.colorScheme.surfaceContainerHigh,
              width: 1,
            ),
          );

    return ListItemStyleWrapper(
        isFirstInSection: widget.isFirstInSection,
        isLastInSection: widget.isLastInSection,
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
                    border: underline,
                    focusedBorder: underline,
                    enabledBorder: underline,
                    disabledBorder: underline,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 7),
                  ),
                ),
              ),
            ],
          );
        });
  }
}
