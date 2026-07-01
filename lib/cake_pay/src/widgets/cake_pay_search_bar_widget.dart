import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:flutter/material.dart';

class CakePaySearchBar extends StatefulWidget {
  const CakePaySearchBar(
      {required this.initialQuery,
      required this.onSearch,
      required this.onFilter,
      this.onCountryPick,
      this.controller,
      this.selectedCountry});

  final String initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;
  final VoidCallback? onCountryPick;
  final Country? selectedCountry;
  final TextEditingController? controller;

  @override
  State<CakePaySearchBar> createState() => _CakePaySearchBarState();
}

class _CakePaySearchBarState extends State<CakePaySearchBar> {
  late final TextEditingController _searchController =
      widget.controller ?? TextEditingController(text: widget.initialQuery);
  final _searchFocusNode = FocusNode();
  final _debounce = Debounce(const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _searchController
        .addListener(() => _debounce.run(() => widget.onSearch(_searchController.text)));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(child: SearchBarWidget(searchController: _searchController)),
          const SizedBox(width: 5),
          _CakePayFilterButton(onFilter: widget.onFilter),
          if (widget.selectedCountry != null)
            _CountryPickerWidget(
              onTap: widget.onCountryPick,
              selectedCountry: widget.selectedCountry!,
            ),
        ],
      ),
    );
  }
}

class _CakePayFilterButton extends StatelessWidget {
  const _CakePayFilterButton({required this.onFilter});

  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFilter,
      child: Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10)),
          child: Image.asset('assets/images/filter_icon.png',
              color: Theme.of(context).colorScheme.onSurface)),
    );
  }
}

class _CountryPickerWidget extends StatelessWidget {
  const _CountryPickerWidget({required this.selectedCountry, this.onTap});

  final Country selectedCountry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Image.asset(selectedCountry.iconPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 24, height: 24)),
              const SizedBox(width: 6),
              Text(
                selectedCountry.countryCode,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
