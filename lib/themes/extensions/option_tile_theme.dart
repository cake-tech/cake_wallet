import 'package:flutter/material.dart';

class OptionTileTheme extends ThemeExtension<OptionTileTheme> {
  final Color titleColor;
  final Color descriptionColor;
  final bool useDarkImage;

  OptionTileTheme(
      {required this.titleColor, required this.descriptionColor, this.useDarkImage = false});

  @override
  OptionTileTheme copyWith({Color? titleColor, Color? descriptionColor, bool? useDarkImage}) =>
      OptionTileTheme(
          titleColor: titleColor ?? this.titleColor,
          descriptionColor: descriptionColor ?? this.descriptionColor,
          useDarkImage: useDarkImage ?? this.useDarkImage);

  @override
  OptionTileTheme lerp(ThemeExtension<OptionTileTheme>? other, double t) {
    if (other is! OptionTileTheme) {
      return this;
    }

    return OptionTileTheme(
        titleColor: Color.lerp(titleColor, other.titleColor, t) ?? titleColor,
        descriptionColor:
            Color.lerp(descriptionColor, other.descriptionColor, t) ?? descriptionColor,
        useDarkImage: other.useDarkImage);
  }
}
