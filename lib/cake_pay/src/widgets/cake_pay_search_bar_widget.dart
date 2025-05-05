import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:flutter/material.dart';

class CakePaySearchBar extends StatefulWidget {
  const CakePaySearchBar(
      {required this.initialQuery,
      required this.onSearch,
      required this.onFilter,
      this.onCountryPick,
      this.selectedCountry});

  final String initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;
  final VoidCallback? onCountryPick;
  final Country? selectedCountry;

  @override
  State<CakePaySearchBar> createState() => _CakePaySearchBarState();
}

class _CakePaySearchBarState extends State<CakePaySearchBar> {
  late final TextEditingController _searchController;
  final _searchFocusNode = FocusNode();
  final _debounce = Debounce(const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
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
          Expanded(
              child: _SearchWidget(controller: _searchController, focusNode: _searchFocusNode)),
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

class _SearchWidget extends StatelessWidget {
  const _SearchWidget({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final searchIcon = ExcludeSemantics(
        child: Icon(Icons.search,
            color: Theme.of(context).extension<FilterTheme>()!.iconColor, size: 24));

    return TextField(
      focusNode: focusNode,
      style: TextStyle(color: Theme.of(context).extension<DashboardPageTheme>()!.textColor),
      controller: controller,
      decoration: InputDecoration(
          filled: true,
          contentPadding: EdgeInsets.only(top: 8, left: 8),
          fillColor: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
          hintText: S.of(context).search,
          hintStyle: TextStyle(
            color: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
          ),
          alignLabelWithHint: true,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          suffixIcon: searchIcon,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(10),
          )),
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
          color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset('assets/images/filter_icon.png',
            color: Theme.of(context).extension<FilterTheme>()!.iconColor),
      ),
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
              color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
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
                  color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
