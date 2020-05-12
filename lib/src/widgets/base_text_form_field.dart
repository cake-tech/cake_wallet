import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
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
    this.textColor = Colors.white,
    this.hintColor = PaletteDark.walletCardText,
    this.borderColor = PaletteDark.menuList,
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
      style: TextStyle(
        fontSize: 16.0,
        color: textColor
      ),
      decoration: InputDecoration(
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 16
        ),
        hintText: hintText,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: borderColor,
            width: 1.0
          )
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: borderColor,
            width: 1.0
          )
        )
      ),
      validator: validator,
    );
  }
}