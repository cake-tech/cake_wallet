import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BaseTextFormField extends StatelessWidget {
  BaseTextFormField({
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.textAlign = TextAlign.start,
    this.autovalidate = false,
    this.hintText = '',
    this.maxLines = 1,
    this.inputFormatters,
    this.textColor,
    this.hintColor,
    this.borderColor,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.enabled = true,
    this.validator
  });

  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextAlign textAlign;
  final bool autovalidate;
  final String hintText;
  final int maxLines;
  final List<TextInputFormatter> inputFormatters;
  final Color textColor;
  final Color hintColor;
  final Color borderColor;
  final Widget prefix;
  final Widget suffix;
  final Widget suffixIcon;
  final bool enabled;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textAlign: textAlign,
      autovalidate: autovalidate,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      enabled: enabled,
      style: TextStyle(
        fontSize: 16.0,
        color: textColor ?? Theme.of(context).primaryTextTheme.title.color
      ),
      decoration: InputDecoration(
        prefix: prefix,
        suffix: suffix,
        suffixIcon: suffixIcon,
        hintStyle: TextStyle(
          color: hintColor ?? Theme.of(context).primaryTextTheme.caption.color,
          fontSize: 16
        ),
        hintText: hintText,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: borderColor ?? Theme.of(context).dividerColor,
            width: 1.0
          )
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: borderColor ?? Theme.of(context).dividerColor,
            width: 1.0
          )
        )
      ),
      validator: validator,
    );
  }
}