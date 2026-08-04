import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_row.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/fiat_currency_search_result.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';

class FiatCurrencyPickerSheet extends StatefulWidget {
  const FiatCurrencyPickerSheet({
    super.key,
    required this.selected,
    required this.onSelected,
    this.cryptoOption,
    this.onCryptoSelected,
  });

  final Object? selected;
  final ValueChanged<FiatCurrency> onSelected;
  final CryptoCurrency? cryptoOption;
  final ValueChanged<CryptoCurrency>? onCryptoSelected;

  static const _popularOrder = <FiatCurrency>[
    FiatCurrency.usd,
    FiatCurrency.eur,
    FiatCurrency.gbp,
    FiatCurrency.jpy,
    FiatCurrency.cny,
  ];

  static Future<void> show({
    required BuildContext context,
    required Object? selected,
    required ValueChanged<FiatCurrency> onSelected,
    CryptoCurrency? cryptoOption,
    ValueChanged<CryptoCurrency>? onCryptoSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FiatCurrencyPickerSheet(
        selected: selected,
        onSelected: onSelected,
        cryptoOption: cryptoOption,
        onCryptoSelected: onCryptoSelected,
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

  void _selectCryptoCurrency(CryptoCurrency c) {
    widget.onCryptoSelected?.call(c);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final selectedFiat = selected is FiatCurrency ? selected : null;
    final popular = FiatCurrencyPickerSheet._popularOrder
        .where((c) => c != selectedFiat)
        .toList(growable: false);
    final query = _searchController.text.trim();
    final filteredAll = _allSorted.where((c) => _matches(c, query)).toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
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
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _isSearching
                  ? FiatCurrencySearchResults(
                      items: filteredAll,
                      onSelected: _selectFiatCurrency,
                      selected: selectedFiat,
                    )
                  : FiatCurrencyPickerBody(
                      selected: selected,
                      cryptoOption: widget.cryptoOption,
                      popular: popular,
                      all: filteredAll,
                      onSelectedFiat: _selectFiatCurrency,
                      onSelectedCrypto: _selectCryptoCurrency,
                    ),
            ),
            CurrencyPickerSearchField(
              controller: _searchController,
              hintText: S.of(context).search,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class FiatCurrencyPickerBody extends StatelessWidget {
  const FiatCurrencyPickerBody({
    super.key,
    required this.selected,
    required this.cryptoOption,
    required this.popular,
    required this.all,
    required this.onSelectedFiat,
    required this.onSelectedCrypto,
  });

  final Object? selected;
  final CryptoCurrency? cryptoOption;
  final List<FiatCurrency> popular;
  final List<FiatCurrency> all;
  final void Function(FiatCurrency) onSelectedFiat;
  final void Function(CryptoCurrency) onSelectedCrypto;

  @override
  Widget build(BuildContext context) {
    final selectedFiat = selected is FiatCurrency ? selected as FiatCurrency : null;
    final selectedCrypto = selected is CryptoCurrency ? selected as CryptoCurrency : null;
    final showCryptoSection = cryptoOption != null && selectedCrypto == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (selectedFiat != null || selectedCrypto != null) ...[
          _SectionHeader(label: S.of(context).picker_section_selected),
          CurrencyPickerListContainer(
            rows: [
              if (selectedFiat != null)
                FiatCurrencyRow(
                  currency: selectedFiat,
                  isSelected: true,
                  onTap: () => onSelectedFiat(selectedFiat),
                ),
              if (selectedCrypto != null)
                _CryptoOptionRow(
                  currency: selectedCrypto,
                  isSelected: true,
                  onTap: () => onSelectedCrypto(selectedCrypto),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (showCryptoSection) ...[
          _SectionHeader(label: S.of(context).picker_section_crypto),
          CurrencyPickerListContainer(
            rows: [
              _CryptoOptionRow(
                currency: cryptoOption!,
                isSelected: false,
                onTap: () => onSelectedCrypto(cryptoOption!),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        if (popular.isNotEmpty) ...[
          _SectionHeader(label: S.of(context).picker_section_popular),
          CurrencyPickerListContainer(
            rows: [
              for (final c in popular)
                FiatCurrencyRow(
                  currency: c,
                  isSelected: false,
                  onTap: () => onSelectedFiat(c),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _SectionHeader(label: S.of(context).picker_section_all_currencies),
        CurrencyPickerListContainer(
          rows: [
            for (final c in all)
              FiatCurrencyRow(
                currency: c,
                isSelected: c == selectedFiat,
                onTap: () => onSelectedFiat(c),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _CryptoOptionRow extends StatelessWidget {
  const _CryptoOptionRow({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  final CryptoCurrency currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            CakeImageWidget(
              imageUrl: currency.iconPath,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currency.fullName ?? currency.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check, size: 20, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
