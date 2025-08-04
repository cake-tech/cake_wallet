import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    required this.searchController,
    this.hintText,
    super.key,
  });

  final TextEditingController searchController;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return BaseTextFormField(
      key: ValueKey('search_bar_widget_key'),
      controller: searchController,
      textStyle: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      hintText: hintText ?? S.of(context).search,
      placeholderTextStyle: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
      alignLabelWithHint: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    );
  }
}
