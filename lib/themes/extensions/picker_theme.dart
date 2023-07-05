import 'package:flutter/material.dart';

class PickerTheme extends ThemeExtension<PickerTheme> {
  final Color dividerColor;

  PickerTheme({required this.dividerColor});

  @override
  PickerTheme copyWith({Color? dividerColor}) =>
      PickerTheme(dividerColor: dividerColor ?? this.dividerColor);

  @override
  PickerTheme lerp(ThemeExtension<PickerTheme>? other, double t) {
    if (other is! PickerTheme) {
      return this;
    }

    return PickerTheme(
        dividerColor:
            Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor);
  }
}
