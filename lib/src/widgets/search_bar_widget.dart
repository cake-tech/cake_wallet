import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    required this.searchController,
    this.hintText,
    this.borderRadius = 14,
  });

  final TextEditingController searchController;
  final String? hintText;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: searchController,
      style: TextStyle(color: Theme.of(context).extension<PickerTheme>()!.searchHintColor),
      decoration: InputDecoration(
        hintText: hintText ?? S.of(context).search_currency,
        hintStyle: TextStyle(color: Theme.of(context).extension<PickerTheme>()!.searchHintColor),
        prefixIcon: Image.asset("assets/images/search_icon.png",
            color: Theme.of(context).extension<PickerTheme>()!.searchIconColor),
        filled: true,
        fillColor: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
        alignLabelWithHint: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: Theme.of(context).extension<PickerTheme>()!.searchBorderColor ??
                  Colors.transparent,
            )),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.transparent,
            )),
      ),
    );
  }
}
