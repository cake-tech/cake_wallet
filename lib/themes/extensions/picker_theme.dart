import 'package:flutter/material.dart';

class PickerTheme extends ThemeExtension<PickerTheme> {
  final Color dividerColor;
  final Color? searchIconColor;
  final Color searchBackgroundFillColor;
  final Color searchTextColor;
  final Color? searchHintColor;
  final Color? searchBorderColor;

  PickerTheme(
      {required this.dividerColor,
      this.searchIconColor,
      required this.searchBackgroundFillColor,
      required this.searchTextColor,
      this.searchHintColor,
      this.searchBorderColor});

  @override
  PickerTheme copyWith(
          {Color? dividerColor,
          Color? searchIconColor,
          Color? searchBackgroundFillColor,
          Color? searchTextColor,
          Color? searchHintColor,
          Color? searchBorderColor}) =>
      PickerTheme(
          dividerColor: dividerColor ?? this.dividerColor,
          searchIconColor: searchIconColor ?? this.searchIconColor,
          searchBackgroundFillColor: searchBackgroundFillColor ?? this.searchBackgroundFillColor,
          searchTextColor: searchTextColor ?? this.searchTextColor,
          searchHintColor: searchHintColor ?? this.searchHintColor,
          searchBorderColor: searchBorderColor ?? this.searchBorderColor);

  @override
  PickerTheme lerp(ThemeExtension<PickerTheme>? other, double t) {
    if (other is! PickerTheme) {
      return this;
    }

    return PickerTheme(
        dividerColor: Color.lerp(dividerColor, other.dividerColor, t) ?? dividerColor,
        searchIconColor: Color.lerp(searchIconColor, other.searchIconColor, t) ?? searchIconColor,
        searchBackgroundFillColor:
            Color.lerp(searchBackgroundFillColor, other.searchBackgroundFillColor, t) ??
                searchBackgroundFillColor,
        searchTextColor: Color.lerp(searchTextColor, other.searchTextColor, t) ?? searchTextColor,
        searchHintColor: Color.lerp(searchHintColor, other.searchHintColor, t) ?? searchHintColor,
        searchBorderColor:
            Color.lerp(searchBorderColor, other.searchBorderColor, t) ?? searchBorderColor);
  }
}
