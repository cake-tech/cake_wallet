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
      style: TextStyle(color: Theme.of(context).primaryTextTheme!.titleLarge!.color!),
      decoration: InputDecoration(
        hintText: hintText ?? S.of(context).search_currency,
        prefixIcon: Image.asset("assets/images/search_icon.png"),
        filled: true,
        fillColor: Theme.of(context).accentTextTheme!.displaySmall!.color!,
        alignLabelWithHint: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(
              color: Colors.transparent,
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
