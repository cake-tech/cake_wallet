import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseTextFormField extends StatelessWidget {
  BaseTextFormField(
      {this.controller,
      this.keyboardType = TextInputType.text,
      this.textInputAction = TextInputAction.done,
      this.textAlign = TextAlign.start,
      this.autovalidateMode,
      this.hintText = '',
      this.maxLines = 1,
      this.inputFormatters,
      this.textColor,
      this.hintColor,
      this.borderColor,
      this.fillColor,
      this.filled,
      this.prefix,
      this.prefixIcon,
      this.suffix,
      this.suffixIcon,
      this.enabled = true,
      this.readOnly = false,
      this.enableInteractiveSelection = true,
      this.obscureText = false,
      this.validator,
      this.textStyle,
      this.placeholderTextStyle,
      this.maxLength,
      this.focusNode,
      this.initialValue,
      this.onSubmit,
      this.borderWidth = 1.0,
      this.hasUnderlineBorder = true,
      this.borderRadius,
      super.key});

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final AutovalidateMode? autovalidateMode;
  final String? hintText;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Color? textColor;
  final Color? hintColor;
  final Color? borderColor;
  final Color? fillColor;
  bool? filled;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final bool? enabled;
  final FormFieldValidator<String>? validator;
  final TextStyle? placeholderTextStyle;
  final TextStyle? textStyle;
  final int? maxLength;
  final FocusNode? focusNode;
  final bool readOnly;
  final bool? enableInteractiveSelection;
  final String? initialValue;
  final double borderWidth;
  final void Function(String)? onSubmit;
  final bool obscureText;
  final bool hasUnderlineBorder;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      enableInteractiveSelection: enableInteractiveSelection,
      readOnly: readOnly,
      initialValue: initialValue,
      focusNode: focusNode,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textAlign: textAlign,
      autovalidateMode: autovalidateMode,
      obscureText: obscureText,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      maxLength: maxLength,
      onFieldSubmitted: onSubmit,
      style: textStyle ??
          Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16.0, color: textColor ?? Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        prefix: prefix,
        prefixIcon: prefixIcon,
        suffix: suffix,
        suffixIcon: suffixIcon,
        fillColor: fillColor ?? Theme.of(context).colorScheme.surfaceContainer,
        filled: filled,
        hintStyle: placeholderTextStyle ??
            Theme.of(context).textTheme.bodyMedium!.copyWith(color: hintColor ?? Theme.of(context).hintColor, fontSize: 16),
        hintText: hintText,
        focusedBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              )
            : OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.all(Radius.circular(4.0)),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              ),
        disabledBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              )
            : OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.all(Radius.circular(10.0)),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              ),
        enabledBorder: hasUnderlineBorder
            ? UnderlineInputBorder(
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              )
            : OutlineInputBorder(
                borderRadius: borderRadius ?? BorderRadius.all(Radius.circular(10.0)),
                borderSide: BorderSide(
                  color: borderColor ?? Theme.of(context).colorScheme.outlineVariant,
                  width: borderWidth,
                ),
              ),
      ),
      validator: validator,
    );
  }
}
