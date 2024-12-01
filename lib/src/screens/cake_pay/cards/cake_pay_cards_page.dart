import 'package:cake_wallet/cake_pay/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/cake_pay_vendor.dart';
import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/card_item.dart';
import 'package:cake_wallet/src/screens/cake_pay/widgets/card_menu.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_cards_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class CakePayCardsPage extends BasePage {
  CakePayCardsPage(this._cardsListViewModel) : searchFocusNode = FocusNode() {
    _searchController.addListener(() {
      if (_searchController.text != _cardsListViewModel.searchString) {
        _searchDebounce.run(() {
          _cardsListViewModel.resetLoadingNextPageState();
          _cardsListViewModel.getVendors(text: _searchController.text);
        });
      }
    });
  }

  final FocusNode searchFocusNode;
  final CakePayCardsListViewModel _cardsListViewModel;

  final _searchDebounce = Debounce(Duration(milliseconds: 500));
  final _searchController = TextEditingController();

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => CardMenu();

  @override
  Widget middle(BuildContext context) {
    return Text(
      'Cake Pay',
      style: textMediumSemiBold(
        color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
      ),
    );
  }

  @override
  Widget trailing(BuildContext context) {
    return _TrailingIcon(
        asset: 'assets/images/profile.png',
        iconColor: pageIconColor(context) ?? Colors.white,
        onPressed: () {
          _cardsListViewModel.isCakePayUserAuthenticated().then((value) {
            if (value) {
              Navigator.pushNamed(context, Routes.cakePayAccountPage);
              return;
            }
            Navigator.pushNamed(context, Routes.cakePayWelcomePage);
          });
        });
  }

  @override
  Widget body(BuildContext context) {

    if (_cardsListViewModel.settingsStore.selectedCakePayCountry == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      reaction((_) => _cardsListViewModel.shouldShowCountryPicker, (bool shouldShowCountryPicker) async {
        if (shouldShowCountryPicker) {
          _cardsListViewModel.storeInitialFilterStates();
          await showCountryPicker(context, _cardsListViewModel);
          if (_cardsListViewModel.hasFiltersChanged) {
            _cardsListViewModel.resetLoadingNextPageState();
            _cardsListViewModel.getVendors();
          }

          _cardsListViewModel.settingsStore.selectedCakePayCountry =
              _cardsListViewModel.selectedCountry;

        }
      });
    });
    }

    final filterButton = Semantics(
      label: S.of(context).filter_by,
      child: GestureDetector(
          onTap: () async {
            _cardsListViewModel.storeInitialFilterStates();
            await showFilterWidget(context);
            if (_cardsListViewModel.hasFiltersChanged) {
              _cardsListViewModel.resetLoadingNextPageState();
              _cardsListViewModel.getVendors();
            }
          },
          child: Container(
              width: 32,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                border: Border.all(
                  color: Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/filter.png',
                color: Theme.of(context).extension<FilterTheme>()!.iconColor,
              ))),
    );
    final _countryPicker = Semantics(
      label: S.of(context).filter_by,
      child: GestureDetector(
        onTap: () async {
          _cardsListViewModel.storeInitialFilterStates();
          await showCountryPicker(context, _cardsListViewModel);
          if (_cardsListViewModel.hasFiltersChanged) {
            _cardsListViewModel.resetLoadingNextPageState();
            _cardsListViewModel.getVendors();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
            border: Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Image.asset(
                  _cardsListViewModel.selectedCountry.iconPath,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 24,
                    height: 24,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  _cardsListViewModel.selectedCountry.countryCode,
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
    );

    return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(children: [
          Container(
              padding: EdgeInsets.only(left: 2, right: 22),
              height: 32,
              child: Row(children: [
                Expanded(
                    child: _SearchWidget(
                  controller: _searchController,
                  focusNode: searchFocusNode,
                )),
                SizedBox(width: 5),
                filterButton,
                SizedBox(width: 5),
                _countryPicker
              ])),
          SizedBox(height: 8),
          Expanded(child: CakePayCardsPageBody(cardsListViewModel: _cardsListViewModel))
        ]));
  }

  Future<void> showFilterWidget(BuildContext context) async {
    return showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return FilterWidget(filterItems: _cardsListViewModel.createFilterItems);
      },
    );
  }
}


Future<void> showCountryPicker(BuildContext context, CakePayCardsListViewModel cardsListViewModel) async {
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
          selectedAtIndex: cardsListViewModel.availableCountries
              .indexOf(cardsListViewModel.selectedCountry),
          onItemSelected: (Country country) =>
              cardsListViewModel.setSelectedCountry(country),
          isSeparated: false,
          hintText: S.of(context).search,
          matchingCriteria: (Country country, String searchText) =>
              country.fullName.toLowerCase().contains(searchText.toLowerCase())));
}

class CakePayCardsPageBody extends StatefulWidget {
  const CakePayCardsPageBody({
    Key? key,
    required this.cardsListViewModel,
  }) : super(key: key);

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  _CakePayCardsPageBodyState createState() => _CakePayCardsPageBodyState();
}

class _CakePayCardsPageBodyState extends State<CakePayCardsPageBody> {
  double get backgroundHeight => MediaQuery.of(context).size.height * 0.75;
  double thumbHeight = 72;

  bool get isAlwaysShowScrollThumb => merchantsList.isEmpty ? false : merchantsList.length > 3;

  List<CakePayVendor> get merchantsList => widget.cardsListViewModel.cakePayVendors;

  final _scrollController = ScrollController();

  @override
  void initState() {
    _scrollController.addListener(() {
      final scrollOffsetFromTop = _scrollController.hasClients
          ? (_scrollController.offset /
              _scrollController.position.maxScrollExtent *
              (backgroundHeight - thumbHeight))
          : 0.0;
      widget.cardsListViewModel.setScrollOffsetFromTop(scrollOffsetFromTop);

      double threshold = 200.0;
      bool isNearBottom =
          _scrollController.offset >= _scrollController.position.maxScrollExtent - threshold;
      if (isNearBottom && !_scrollController.position.outOfRange) {
        widget.cardsListViewModel.fetchNextPage();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final vendorsState = widget.cardsListViewModel.vendorsState;
      if (vendorsState is CakePayVendorLoadedState) {
        bool isLoadingMore = widget.cardsListViewModel.isLoadingNextPage;
        final vendors = widget.cardsListViewModel.cakePayVendors;

        if (vendors.isEmpty) {
          return Center(child: Text(S.of(context).no_cards_found));
        }
        return Stack(children: [
          GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsiveLayoutUtil.shouldRenderTabletUI ? 2 : 1,
              childAspectRatio: 5,
              crossAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
              mainAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
            ),
            padding: EdgeInsets.only(left: 2, right: 22),
            itemCount: vendors.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (_, index) {
              if (index >= vendors.length) {
                return _VendorLoadedIndicator();
              }
              final vendor = vendors[index];
              return CardItem(
                logoUrl: vendor.card?.cardImageUrl,
                onTap: () {
                  Navigator.of(context).pushNamed(Routes.cakePayBuyCardPage, arguments: [vendor]);
                },
                title: vendor.name,
                subTitle: vendor.card?.description ?? '',
                backgroundColor:
                    Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                titleColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                subtitleColor: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                discount: 0.0,
              );
            },
          ),
          isAlwaysShowScrollThumb
              ? CakeScrollbar(
                  backgroundHeight: backgroundHeight,
                  thumbHeight: thumbHeight,
                  rightOffset: 1,
                  width: 3,
                  backgroundColor:
                      Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(0.05),
                  thumbColor:
                      Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(0.5),
                  fromTop: widget.cardsListViewModel.scrollOffsetFromTop,
                )
              : Offstage()
        ]);
      }
      return _VendorLoadedIndicator();
    });
  }
}

class _VendorLoadedIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        backgroundColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
        valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor),
      ),
    );
  }
}

class _SearchWidget extends StatelessWidget {
  const _SearchWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final searchIcon = ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Image.asset(
          'assets/images/mini_search_icon.png',
          color: Theme.of(context).extension<FilterTheme>()!.iconColor,
        ),
      ),
    );

    return TextField(
      focusNode: focusNode,
      style: TextStyle(color: Theme.of(context).extension<DashboardPageTheme>()!.textColor),
      controller: controller,
      decoration: InputDecoration(
          filled: true,
          contentPadding: EdgeInsets.only(
            top: 10,
            left: 10,
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
    );
  }
}

class _TrailingIcon extends StatelessWidget {
  const _TrailingIcon({required this.asset, this.onPressed, required this.iconColor});

  final String asset;
  final VoidCallback? onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: S.of(context).profile,
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            highlightColor: Colors.transparent,
            onPressed: onPressed,
            icon: ImageIcon(AssetImage(asset), size: 25, color: iconColor),
          ),
        ));
  }
}
