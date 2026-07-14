import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_row.dart';
import 'package:flutter/material.dart';

class FiatCurrencySearchResults extends StatelessWidget {
  const FiatCurrencySearchResults({
    super.key,
    required this.items,
    required this.onSelected,
    required this.selected,
  });

  final List<FiatCurrency> items;
  final void Function(FiatCurrency) onSelected;
  final FiatCurrency? selected;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            S.of(context).picker_no_matches,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        CurrencyPickerListContainer(
          rows: [
            for (final c in items)
              FiatCurrencyRow(
                currency: c,
                isSelected: c == selected,
                onTap: () => onSelected(c),
              ),
          ],
        ),
      ],
    );
  }
}
