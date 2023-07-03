import 'package:flutter/material.dart';

class AddressTheme extends ThemeExtension<AddressTheme> {
  final Color actionButtonColor;

  AddressTheme({required this.actionButtonColor});

  @override
  AddressTheme copyWith({Color? actionButtonColor}) => AddressTheme(
      actionButtonColor: actionButtonColor ?? this.actionButtonColor);

  @override
  AddressTheme lerp(ThemeExtension<AddressTheme>? other, double t) {
    if (other is! AddressTheme) {
      return this;
    }

    return AddressTheme(
      actionButtonColor:
          Color.lerp(actionButtonColor, other.actionButtonColor, t) ??
              actionButtonColor,
    );
  }
}
