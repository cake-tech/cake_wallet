import 'package:flutter/material.dart';

class StandardTextFormFieldWidget extends StatelessWidget {
  const StandardTextFormFieldWidget({
    super.key,
    required this.controller,
    required this.labelText,
    required this.fillColor,
    required this.addressValidator,
    this.focusNode,
    this.suffixIcon,
    this.prefixIcon,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final Color fillColor;
  final String? Function(String?)? addressValidator;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Widget? suffix;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
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
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          suffixIcon: Padding(padding: const EdgeInsets.only(right: 10), child: suffixIcon),
          suffix: suffix,
          prefixIcon: prefixIcon,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 34,
            maxWidth: 34,
            minHeight: 24,
            maxHeight: 24,
          )),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
      validator: addressValidator,
    );
  }
}
