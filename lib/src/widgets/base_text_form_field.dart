import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
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
      this.prefix,
      this.prefixIcon,
      this.suffix,
      this.suffixIcon,
      this.enabled = true,
      this.readOnly = false,
      this.enableInteractiveSelection = true,
      this.validator,
      this.textStyle,
      this.placeholderTextStyle,
      this.maxLength,
      this.focusNode,
      this.initialValue,
      this.onSubmit,
      this.borderWidth = 1.0});

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
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      maxLength: maxLength,
      onFieldSubmitted: onSubmit,
      style: textStyle ??
          TextStyle(
              fontSize: 16.0,
              color: textColor ??
                  Theme.of(context).extension<CakeTextTheme>()!.titleColor),
      decoration: InputDecoration(
          prefix: prefix,
          prefixIcon: prefixIcon,
          suffix: suffix,
          suffixIcon: suffixIcon,
          hintStyle: placeholderTextStyle ??
              TextStyle(
                  color: hintColor ?? Theme.of(context).hintColor,
                  fontSize: 16),
          hintText: hintText,
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: borderColor ??
                      Theme.of(context).extension<CakeTextTheme>()!.textfieldUnderlineColor,
                  width: borderWidth)),
          disabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: borderColor ??
                      Theme.of(context).extension<CakeTextTheme>()!.textfieldUnderlineColor,
                  width: borderWidth)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: borderColor ??
                      Theme.of(context).extension<CakeTextTheme>()!.textfieldUnderlineColor,
                  width: borderWidth))),
      validator: validator,
    );
  }
}
