import 'package:flutter/material.dart';

const latoFont = "Lato";

TextStyle textXxSmall({Color? color}) => _cakeRegular(10, color);

TextStyle textXxSmallSemiBold({Color? color}) => _cakeSemiBold(10, color);

TextStyle textXSmall({Color? color}) => _cakeRegular(12, color);

TextStyle textXSmallSemiBold({Color? color}) => _cakeSemiBold(12, color);

TextStyle textSmall({Color? color}) => _cakeRegular(14, color);

TextStyle textSmallSemiBold({Color? color}) => _cakeSemiBold(14, color);

TextStyle textMedium({Color? color}) => _cakeRegular(16, color);

TextStyle textMediumBold({Color? color}) => _cakeBold(16, color);

TextStyle textMediumSemiBold({Color? color}) => _cakeSemiBold(22, color);

TextStyle textLarge({Color? color}) => _cakeRegular(18, color);

TextStyle textLargeSemiBold({Color? color}) => _cakeSemiBold(24, color);

TextStyle textXLarge({Color? color}) => _cakeRegular(32, color);

TextStyle textXLargeSemiBold({Color? color}) => _cakeSemiBold(32, color);

TextStyle _cakeRegular(double size, Color? color) => _textStyle(
      size: size,
      fontWeight: FontWeight.normal,
      color: color,
    );

TextStyle _cakeBold(double size, Color? color) => _textStyle(
      size: size,
      fontWeight: FontWeight.w900,
      color: color,
    );

TextStyle _cakeSemiBold(double size, Color? color) => _textStyle(
      size: size,
      fontWeight: FontWeight.w700,
      color: color,
    );

TextStyle _textStyle({
  required double size,
  required FontWeight fontWeight,
  Color? color,
}) =>
    TextStyle(
      fontFamily: latoFont,
      fontSize: size,
      fontWeight: fontWeight,
      color: color ?? Colors.white,
    );
