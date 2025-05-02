import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_cards_list_view_model.dart';
import 'package:flutter/material.dart';

class CakePaySearchBar extends StatelessWidget {
  const CakePaySearchBar({required this.cardsListViewModel, this.showCountryPicker = true});

  final CakePayCardsListViewModel cardsListViewModel;
  final bool showCountryPicker;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 32,
        child: Row(children: [
          _SearchWidget(cardsListViewModel: cardsListViewModel),
          SizedBox(width: 5),
          _CakePayFilterButton(cardsListViewModel: cardsListViewModel),
          if (showCountryPicker) _CountryPickerWidget(cardsListViewModel: cardsListViewModel)
        ]));
  }
}

class _SearchWidget extends StatefulWidget {
  const _SearchWidget({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  State<_SearchWidget> createState() => _SearchWidgetState(cardsListViewModel);
}

class _SearchWidgetState extends State<_SearchWidget> {
  _SearchWidgetState(this._cardsListViewModel);

  final CakePayCardsListViewModel _cardsListViewModel;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _searchDebounce = Debounce(Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _cardsListViewModel.searchString) {
        _searchDebounce.run(() {
          _cardsListViewModel.resetLoadingNextPageState();
          _cardsListViewModel.getVendors(text: _searchController.text);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchIcon = ExcludeSemantics(
      child: Icon(
        Icons.search,
        color: Theme.of(context).extension<FilterTheme>()!.iconColor,
        //size: 24
      ),
    );

    return Expanded(
      child: TextField(
        focusNode: _searchFocusNode,
        style: TextStyle(color: Theme.of(context).extension<DashboardPageTheme>()!.textColor),
        controller: _searchController,
        decoration: InputDecoration(
            filled: true,
            contentPadding: EdgeInsets.only(
              top: 8,
              left: 8,
            ),
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
      ),
    );
  }
}

class _CakePayFilterButton extends StatelessWidget {
  _CakePayFilterButton({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).filter_by,
      child: GestureDetector(
          onTap: () async {
            cardsListViewModel.storeInitialFilterStates();
            await showFilterWidget(context);
            if (cardsListViewModel.hasFiltersChanged) {
              cardsListViewModel.resetLoadingNextPageState();
              cardsListViewModel.getVendors();
            }
          },
          child: Container(
              width: 32,
              padding: EdgeInsets.only(top: 7, bottom: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                border: Border.all(
                  color: Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/filter_icon.png',
                color: Theme.of(context).extension<FilterTheme>()!.iconColor,
              ))),
    );
  }

  Future<void> showFilterWidget(BuildContext context) async {
    return showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return FilterWidget(filterItems: cardsListViewModel.createFilterItems);
      },
    );
  }
}

class _CountryPickerWidget extends StatelessWidget {
  _CountryPickerWidget({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Semantics(
        label: S.of(context).filter_by,
        child: GestureDetector(
          onTap: () async {
            cardsListViewModel.storeInitialFilterStates();
            await showCountryPicker(context, cardsListViewModel);
            if (cardsListViewModel.hasFiltersChanged) {
              cardsListViewModel.resetLoadingNextPageState();
              cardsListViewModel.getVendors();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Image.asset(
                    cardsListViewModel.selectedCountry.iconPath,
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 24,
                      height: 24,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    cardsListViewModel.selectedCountry.countryCode,
                    style: TextStyle(
                      color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showCountryPicker(
      BuildContext context, CakePayCardsListViewModel cardsListViewModel) async {
    await showPopUp<void>(
        context: context,
        builder: (_) => Picker(
            title: S.of(context).select_your_country,
            items: cardsListViewModel.availableCountries,
            images: cardsListViewModel.availableCountries
                .map((e) => Image.asset(
                      e.iconPath,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 58,
                        height: 58,
                      ),
                    ))
                .toList(),
            selectedAtIndex:
                cardsListViewModel.availableCountries.indexOf(cardsListViewModel.selectedCountry),
            onItemSelected: (Country country) => cardsListViewModel.setSelectedCountry(country),
            isSeparated: false,
            hintText: S.of(context).search,
            matchingCriteria: (Country country, String searchText) =>
                country.fullName.toLowerCase().contains(searchText.toLowerCase())));
  }
}
