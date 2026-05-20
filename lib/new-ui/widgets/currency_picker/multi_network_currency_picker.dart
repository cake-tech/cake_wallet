import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/chain_chip_strip.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_list_container.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/picker_section_header.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/pill_grid.dart';
import 'package:cake_wallet/new-ui/widgets/currency_picker/select_network_page.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/currency_groups.dart';
import 'package:cw_core/db/currency_picker_recents_storage.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class MultiNetworkCurrencyPicker extends StatefulWidget {
  const MultiNetworkCurrencyPicker({super.key, required this.args});

  final CurrencyPickerArgs args;

  @override
  State<MultiNetworkCurrencyPicker> createState() => _MultiNetworkCurrencyPickerState();
}

class _MultiNetworkCurrencyPickerState extends State<MultiNetworkCurrencyPicker> {
  bool _recentsLoaded = false;
  WalletType? _selectedNetwork;
  List<CryptoCurrency> _recents = const [];
  final TextEditingController _searchController = TextEditingController();

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  late final List<WalletType> _networks = widget.args.items
      .map(cryptoCurrencyOrTokenToWalletType)
      .whereType<WalletType>()
      .toSet()
      .toList();

  Set<CryptoCurrency> get _natives =>
      {for (final wt in availableWalletTypes) walletTypeToCryptoCurrency(wt)};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadRecents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final resolved = await CurrencyPickerRecentsStorage.loadRecents(
      context: widget.args.pickerContext,
      resolveFrom: widget.args.items,
      limit: 6,
    );
    if (!mounted) return;
    setState(() {
      _recents = resolved;
      _recentsLoaded = true;
    });
  }

  bool _matchesNetwork(CryptoCurrency c) {
    if (_selectedNetwork == null) return true;
    return cryptoCurrencyOrTokenToWalletType(c) == _selectedNetwork;
  }

  List<CryptoCurrency> get _visibleItems {
    final query = _searchController.text.trim();
    return widget.args.items
        .where((c) => currencyMatchesQuery(c, query) && _matchesNetwork(c))
        .toList(growable: false);
  }

  void _recordAndNotify(CryptoCurrency currency) {
    CurrencyPickerRecentsStorage.recordRecent(
      currency: currency,
      context: widget.args.pickerContext,
    );
    widget.args.onSelected(currency);
  }

  void _selectCurrency(CryptoCurrency currency) {
    _recordAndNotify(currency);
    Navigator.of(context).maybePop();
  }

  void _onStablecoinPillTapped(CryptoCurrency tapped) {
    final variants = widget.args.items
        .where((c) =>
            c.groups.contains(CurrencyGroups.stablecoin) &&
            c.title.toUpperCase() == tapped.title.toUpperCase())
        .toList(growable: false);

    if (variants.length <= 1) {
      _selectCurrency(tapped);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SelectNetworkPage(
          assetTitle: tapped.title,
          assetFullName: tapped.fullName,
          assetIconPath: tapped.iconPath,
          variants: variants,
          onSelected: _recordAndNotify,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (_networks.length > 1)
          ChainChipStrip(
            walletTypes: _networks,
            selected: _selectedNetwork,
            onSelected: (network) => setState(() => _selectedNetwork = network),
          ),
        Expanded(
          child: _MultiNetworkPickerBody(
            items: _visibleItems,
            isSearching: _isSearching,
            recents: _recents,
            recentsLoaded: _recentsLoaded,
            natives: _natives,
            selected: widget.args.selected,
            symbolResolver: widget.args.symbolResolver,
            onSelect: _selectCurrency,
            onStablecoinTap: _onStablecoinPillTapped,
          ),
        ),
        CurrencyPickerSearchField(
          controller: _searchController,
          hintText: S.of(context).search,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MultiNetworkPickerBody extends StatefulWidget {
  const _MultiNetworkPickerBody({
    required this.items,
    required this.isSearching,
    required this.recents,
    required this.recentsLoaded,
    required this.natives,
    required this.selected,
    required this.symbolResolver,
    required this.onSelect,
    required this.onStablecoinTap,
  });

  final bool isSearching;
  final bool recentsLoaded;
  final CryptoCurrency? selected;
  final List<CryptoCurrency> items;
  final List<CryptoCurrency> recents;
  final Set<CryptoCurrency> natives;
  final void Function(CryptoCurrency) onSelect;
  final String Function(CryptoCurrency) symbolResolver;
  final void Function(CryptoCurrency) onStablecoinTap;

  @override
  State<_MultiNetworkPickerBody> createState() => _MultiNetworkPickerBodyState();
}

class _MultiNetworkPickerBodyState extends State<_MultiNetworkPickerBody> {
  static const int _previewCount = 3;

  bool _moreCryptosSectionExpanded = false;
  bool _xstocksSectionExpanded = false;

  @override
  void initState() {
    super.initState();
    final selected = widget.selected;
    if (selected == null) return;

    final moreCryptos = _computeMoreCryptosSection(widget.items);
    final xstocks = _computeXstocksSection(widget.items);

    if (moreCryptos.indexOf(selected) >= _previewCount) {
      _moreCryptosSectionExpanded = true;
    }

    if (xstocks.indexOf(selected) >= _previewCount) {
      _xstocksSectionExpanded = true;
    }
  }

  List<CryptoCurrency> _computeMoreCryptosSection(List<CryptoCurrency> from) {
    final list = from
        .where((c) =>
            !widget.natives.contains(c) &&
            cryptoCurrencyOrTokenToWalletType(c) == null &&
            c.tag == null &&
            !c.groups.contains(CurrencyGroups.stablecoin) &&
            !c.groups.contains(CurrencyGroups.tokenizedStock))
        .toList();

    list.sort((a, b) => (a.fullName ?? a.title).toLowerCase().compareTo(
          (b.fullName ?? b.title).toLowerCase(),
        ));

    return list;
  }

  List<CryptoCurrency> _computeXstocksSection(List<CryptoCurrency> from) {
    return from
        .where((c) => c.groups.contains(CurrencyGroups.tokenizedStock))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final isSearching = widget.isSearching;
    final recents = widget.recents;
    final recentsLoaded = widget.recentsLoaded;
    final natives = widget.natives;
    final selected = widget.selected;
    final symbolResolver = widget.symbolResolver;
    final onSelect = widget.onSelect;
    final onStablecoinTap = widget.onStablecoinTap;

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

    if (isSearching) {
      final duplicated = _duplicatedTitles(items);
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          CurrencyPickerListContainer(
            rows: [
              for (final item in items)
                CurrencyPickerRow(
                  currency: item,
                  isSelected: selected != null && selected == item,
                  chainPillLabel: duplicated.contains(item.title.toUpperCase())
                      ? _chainPillLabelFor(item)
                      : null,
                  chainBadgePath: duplicated.contains(item.title.toUpperCase())
                      ? _chainBadgePathFor(item)
                      : null,
                  trailing: _SymbolTrailing(
                    currency: item,
                    symbolResolver: symbolResolver,
                  ),
                  onTap: () => onSelect(item),
                ),
            ],
          ),
        ],
      );
    }

    final visibleRecents = recents.where(items.contains).toList(growable: false);

    final seenStablecoinTitles = <String>{};
    final stablecoins = items
        .where((c) =>
            c.groups.contains(CurrencyGroups.stablecoin) &&
            seenStablecoinTitles.add(c.title.toUpperCase()))
        .toList(growable: false);

    final cryptocurrencies = items.where(natives.contains).toList(growable: false);
    final moreCryptos = _computeMoreCryptosSection(items);
    final xstocks = _computeXstocksSection(items);
    final allAssets = [...items]..sort((a, b) => (a.fullName ?? a.title).toLowerCase().compareTo(
          (b.fullName ?? b.title).toLowerCase(),
        ));

    final section = _selectedSection(
      recents: visibleRecents,
      stablecoins: stablecoins,
      cryptocurrencies: cryptocurrencies,
      moreCryptos: moreCryptos,
      xstocks: xstocks,
    );

    final moreCryptosVisible = _moreCryptosSectionExpanded
        ? moreCryptos
        : moreCryptos.take(_previewCount).toList(growable: false);
    final xstocksVisible =
        _xstocksSectionExpanded ? xstocks : xstocks.take(_previewCount).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (recentsLoaded && visibleRecents.isNotEmpty)
          _PickerSection(
            title: S.of(context).picker_section_recents,
            child: PillGrid(
              items: visibleRecents,
              selected: section == _SelSection.recents ? selected : null,
              onTap: onSelect,
              symbolResolver: symbolResolver,
            ),
          ),
        if (stablecoins.isNotEmpty)
          _PickerSection(
            title: S.of(context).picker_section_stablecoins,
            child: PillGrid(
              items: stablecoins,
              selected: section == _SelSection.stablecoins ? selected : null,
              onTap: onStablecoinTap,
              symbolResolver: symbolResolver,
            ),
          ),
        if (cryptocurrencies.isNotEmpty)
          _PickerSection(
            title: S.of(context).picker_section_cryptocurrencies,
            child: CurrencyPickerListContainer(
              rows: [
                for (final item in cryptocurrencies)
                  CurrencyPickerRow(
                    currency: item,
                    isSelected: section == _SelSection.cryptocurrencies && selected == item,
                    trailing: _SymbolTrailing(
                      currency: item,
                      symbolResolver: symbolResolver,
                    ),
                    onTap: () => onSelect(item),
                  ),
              ],
            ),
          ),
        if (moreCryptos.isNotEmpty)
          _PickerSection(
            title: S.of(context).picker_section_more_cryptocurrencies,
            child: CurrencyPickerListContainer(
              rows: [
                for (final item in moreCryptosVisible)
                  CurrencyPickerRow(
                    currency: item,
                    isSelected: section == _SelSection.moreCryptocurrencies && selected == item,
                    trailing: _SymbolTrailing(
                      currency: item,
                      symbolResolver: symbolResolver,
                    ),
                    onTap: () => onSelect(item),
                  ),
                if (moreCryptos.length > _previewCount)
                  _SeeAllRow(
                    expanded: _moreCryptosSectionExpanded,
                    onTap: () =>
                        setState(() => _moreCryptosSectionExpanded = !_moreCryptosSectionExpanded),
                  ),
              ],
            ),
          ),
        if (xstocks.isNotEmpty)
          _PickerSection(
            title: S.of(context).picker_section_tokenized_stocks,
            child: CurrencyPickerListContainer(
              rows: [
                for (final item in xstocksVisible)
                  CurrencyPickerRow(
                    currency: item,
                    isSelected: section == _SelSection.xstocks && selected == item,
                    trailing: _SymbolTrailing(
                      currency: item,
                      symbolResolver: symbolResolver,
                    ),
                    onTap: () => onSelect(item),
                  ),
                if (xstocks.length > _previewCount)
                  _SeeAllRow(
                    expanded: _xstocksSectionExpanded,
                    onTap: () => setState(() => _xstocksSectionExpanded = !_xstocksSectionExpanded),
                  ),
              ],
            ),
          ),
        if (allAssets.isNotEmpty)
          _PickerSection(
            title: S.of(context).picker_section_all_assets,
            child: CurrencyPickerListContainer(
              rows: [
                for (final item in allAssets)
                  CurrencyPickerRow(
                    currency: item,
                    isSelected: section == _SelSection.allAssets && selected == item,
                    chainPillLabel: _chainPillLabelFor(item),
                    chainBadgePath: _chainBadgePathFor(item),
                    trailing: _SymbolTrailing(
                      currency: item,
                      symbolResolver: symbolResolver,
                    ),
                    onTap: () => onSelect(item),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  String? _chainPillLabelFor(CryptoCurrency c) {
    if (c == CryptoCurrency.btcln) return chainNameForCurrency(c);
    if (widget.natives.contains(c)) return null;
    if (cryptoCurrencyOrTokenToWalletType(c) == null) return null;
    return chainNameForCurrency(c);
  }

  String? _chainBadgePathFor(CryptoCurrency c) {
    if (widget.natives.contains(c)) return null;
    final wt = cryptoCurrencyOrTokenToWalletType(c);
    return wt == null ? null : walletTypeToCryptoCurrency(wt).chainIconPath;
  }

  Set<String> _duplicatedTitles(Iterable<CryptoCurrency> list) {
    final seen = <String>{};
    final dup = <String>{};
    for (final c in list) {
      final key = c.title.toUpperCase();
      if (!seen.add(key)) dup.add(key);
    }
    return dup;
  }

  _SelSection? _selectedSection({
    required List<CryptoCurrency> recents,
    required List<CryptoCurrency> stablecoins,
    required List<CryptoCurrency> cryptocurrencies,
    required List<CryptoCurrency> moreCryptos,
    required List<CryptoCurrency> xstocks,
  }) {
    final s = widget.selected;
    if (s == null) return null;
    if (recents.contains(s)) return _SelSection.recents;
    if (stablecoins.any((c) => c.title.toUpperCase() == s.title.toUpperCase())) {
      return _SelSection.stablecoins;
    }
    if (cryptocurrencies.contains(s)) return _SelSection.cryptocurrencies;
    if (moreCryptos.contains(s)) return _SelSection.moreCryptocurrencies;
    if (xstocks.contains(s)) return _SelSection.xstocks;
    return _SelSection.allAssets;
  }
}

class _PickerSection extends StatelessWidget {
  const _PickerSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PickerSectionHeader(title: title),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SymbolTrailing extends StatelessWidget {
  const _SymbolTrailing({
    required this.currency,
    required this.symbolResolver,
  });

  final CryptoCurrency currency;
  final String Function(CryptoCurrency) symbolResolver;

  @override
  Widget build(BuildContext context) {
    return Text(
      symbolResolver(currency),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _SeeAllRow extends StatelessWidget {
  const _SeeAllRow({
    required this.expanded,
    required this.onTap,
  });

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = expanded ? S.of(context).picker_show_less : S.of(context).picker_see_all;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

enum _SelSection {
  recents,
  stablecoins,
  cryptocurrencies,
  moreCryptocurrencies,
  xstocks,
  allAssets,
}
