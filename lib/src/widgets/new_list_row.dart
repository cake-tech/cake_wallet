import 'package:cake_wallet/src/widgets/rounded_checkbox.dart';
import 'package:cake_wallet/src/widgets/simple_checkbox.dart';
import 'package:flutter/material.dart';

enum NewListRowType { textFormField, checkbox, dropdown, toggle, none }

class NewListRow extends StatefulWidget {
  NewListRow({
    this.type = NewListRowType.none,
    required this.key,
    this.controller,
    required this.label,
    this.initialValue,
    this.isFirstInSection = false,
    this.isLastInSection = false,
    this.checkboxValue = false,
    this.onCheckboxChanged,
    this.validator,
  });

  final NewListRowType type;
  final ValueKey<String> key;
  final TextEditingController? controller;
  final String label;
  final String? initialValue;
  final bool isFirstInSection;
  final bool isLastInSection;
  final bool checkboxValue;
  final ValueChanged<bool>? onCheckboxChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<NewListRow> createState() =>
      _NewListRowState(checkboxValue: checkboxValue);
}

class _NewListRowState extends State<NewListRow> {
  _NewListRowState({required this.checkboxValue, this.onCheckboxChanged});

  bool checkboxValue;
  final ValueChanged<bool>? onCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceContainer;
    final borderSide =
        BorderSide(color: theme.colorScheme.surfaceContainerHigh, width: 1);
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(widget.isFirstInSection ? 16.0 : 0.0),
      bottom: Radius.circular(widget.isLastInSection ? 16.0 : 0.0),
    );
    final underlineInputBorder = widget.isLastInSection
        ? InputBorder.none
        : UnderlineInputBorder(borderSide: borderSide);
    final TextStyle _textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurface,
    );
    final TextStyle _labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurfaceVariant,
    );

    final textFormField = TextFormField(
      key: widget.key,
      controller: widget.controller,
      style: _textStyle,
      validator: widget.validator,
      decoration: InputDecoration(
        fillColor: backgroundColor,
        labelText: widget.label,
        labelStyle: _labelStyle,
        border: underlineInputBorder,
        focusedBorder: underlineInputBorder,
        enabledBorder: underlineInputBorder,
        disabledBorder: underlineInputBorder,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 7.0),
      ),
    );

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                  color: backgroundColor, borderRadius: borderRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: widget.type == NewListRowType.textFormField
                    ? textFormField
                    : Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: widget.isLastInSection
                              ? null
                              : Border(
                                  bottom: borderSide,
                                ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.label, style: _textStyle),
                            NewStandardRoundCheckbox(
                              value: checkboxValue,
                              onChanged: (bool newValue) {
                                setState(() => checkboxValue = newValue);
                                widget.onCheckboxChanged?.call(newValue);
                              },
                            ),
                          ],
                        )),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NewStandardRoundCheckbox extends StatelessWidget {
  const NewStandardRoundCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        decoration: BoxDecoration(
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(50)),
        ),
        height: 24,
        width: 24,
        child: value
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
