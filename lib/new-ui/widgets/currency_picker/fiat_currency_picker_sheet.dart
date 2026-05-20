import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_row.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_search_result.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';

class FiatCurrencyPickerSheet extends StatefulWidget {
  const FiatCurrencyPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FiatCurrency? selected;
  final ValueChanged<FiatCurrency> onSelected;

  static const _popularOrder = <FiatCurrency>[
    FiatCurrency.usd,
    FiatCurrency.eur,
    FiatCurrency.gbp,
    FiatCurrency.jpy,
    FiatCurrency.cny,
  ];

  static Future<void> show({
    required BuildContext context,
    required FiatCurrency? selected,
    required ValueChanged<FiatCurrency> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiatCurrencyPickerSheet(
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<FiatCurrencyPickerSheet> createState() => _FiatCurrencyPickerSheetState();
}

class _FiatCurrencyPickerSheetState extends State<FiatCurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late final List<FiatCurrency> _allSorted = [...FiatCurrency.all]..sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(FiatCurrency c, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return c.fullName.toLowerCase().contains(q) || c.title.toLowerCase().contains(q);
  }

  void _selectFiatCurrency(FiatCurrency c) {
    widget.onSelected(c);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final popular =
        FiatCurrencyPickerSheet._popularOrder.where((c) => c != selected).toList(growable: false);
    final query = _searchController.text.trim();
    final filteredAll = _allSorted.where((c) => _matches(c, query)).toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: colors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          ModalTopBar(
            title: S.of(context).select_fiat_currency_title,
            leadingIcon: const Icon(Icons.close),
            onLeadingPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: _isSearching
                ? FiatCurrencySearchResults(
                    items: filteredAll,
                    onSelected: _selectFiatCurrency,
                    isSelected: selected == widget.selected,
                  )
                : FiatCurrencyPickerBody(
                    isSelected: selected,
                    popular: popular,
                    all: filteredAll,
                    onSelected: _selectFiatCurrency,
                  ),
          ),
          CurrencyPickerSearchField(
            controller: _searchController,
            hintText: S.of(context).search,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class FiatCurrencyPickerBody extends StatelessWidget {
  const FiatCurrencyPickerBody({
    super.key,
    required this.isSelected,
    required this.popular,
    required this.all,
    required this.onSelected,
  });

  final FiatCurrency? isSelected;
  final List<FiatCurrency> popular;
  final List<FiatCurrency> all;
  final void Function(FiatCurrency) onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (isSelected != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              S.of(context).picker_section_selected,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ),
          ),
          CurrencyPickerListContainer(
            rows: [
              FiatCurrencyRow(
                currency: isSelected!,
                isSelected: true,
                onTap: () => onSelected(isSelected!),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (popular.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              S.of(context).picker_section_popular,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ),
          ),
          CurrencyPickerListContainer(
            rows: [
              for (final c in popular)
                FiatCurrencyRow(
                  currency: c,
                  isSelected: false,
                  onTap: () => onSelected(c),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            S.of(context).picker_section_all_currencies,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ),
        ),
        CurrencyPickerListContainer(
          rows: [
            for (final c in all)
              FiatCurrencyRow(
                currency: c,
                isSelected: c == isSelected,
                onTap: () => onSelected(c),
              ),
          ],
        ),
      ],
    );
  }
}

