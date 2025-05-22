import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    required this.searchController,
    this.hintText,
    this.borderRadius = 14,
    this.enabledBorderColor,
    super.key,
  });

  final TextEditingController searchController;
  final String? hintText;
  final double borderRadius;
  final Color? enabledBorderColor;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('search_bar_widget_key'),
      controller: searchController,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      decoration: InputDecoration(
        hintText: hintText ?? S.of(context).search,
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        alignLabelWithHint: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: enabledBorderColor ?? Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
