import 'package:flutter/material.dart';

class ListItemTextFieldWidget extends StatefulWidget {
  const ListItemTextFieldWidget({
    super.key,
    required this.keyValue,
    required this.label,
    required this.controller,
    this.validator,
    this.onChanged,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
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

    final underline = widget.isLastInSection
        ? InputBorder.none
        : UnderlineInputBorder(
      borderSide: BorderSide(
        color: theme.colorScheme.surfaceContainerHigh,
        width: 1,
      ),
    );

    final radius = BorderRadius.vertical(
      top: Radius.circular(widget.isFirstInSection ? 16 : 0),
      bottom: Radius.circular(widget.isLastInSection ? 16 : 0),
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        color: theme.colorScheme.surfaceContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
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
    );
  }
}
