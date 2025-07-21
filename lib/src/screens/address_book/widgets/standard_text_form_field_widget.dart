import 'package:flutter/material.dart';

class StandardTextFormFieldWidget extends StatelessWidget {
  const StandardTextFormFieldWidget({
    super.key,
    required this.controller,
    required this.labelText,
    required this.fillColor,
    required this.validator,
    this.focusNode,
    this.suffixIcon,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
    this.suffixIconConstraints,
    this.prefixIconConstraints,
    this.outlineInputBorder,
    this.enabledInputBorder,
    this.focusedInputBorder,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String labelText;
  final Color fillColor;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Widget? suffix;
  final BoxConstraints? suffixIconConstraints;
  final BoxConstraints? prefixIconConstraints;
  final void Function(String)? onChanged;
  final InputBorder? outlineInputBorder;
  final InputBorder? enabledInputBorder;
  final InputBorder? focusedInputBorder;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelText: labelText,
          labelStyle:
              Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).hintColor),
          hintStyle:
              Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).hintColor),
          fillColor: fillColor,
          border: outlineInputBorder ??
              OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
          enabledBorder: enabledInputBorder ??
              OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide(color: Colors.transparent)),
          focusedBorder: focusedInputBorder ??
              OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          suffixIcon: Padding(padding: const EdgeInsets.only(right: 10), child: suffixIcon),
          suffix: suffix,
          prefixIcon: prefixIcon,
          prefixIconConstraints: prefixIconConstraints,
          suffixIconConstraints: suffixIconConstraints ??
              const BoxConstraints(
                minWidth: 34,
                maxWidth: 34,
                minHeight: 24,
                maxHeight: 24,
              )),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
