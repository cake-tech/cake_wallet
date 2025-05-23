import 'package:cake_wallet/cake_pay/src/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_search_bar_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/user_card_item.dart';
import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/cake_pay/src/widgets/card_item.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/cake_pay_card_info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/tab_view_wrapper_widget.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_cards_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class CakePayCardsPage extends BasePage {
  CakePayCardsPage(this._cardsListViewModel);

  final CakePayCardsListViewModel _cardsListViewModel;

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

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
    return Observer(builder: (_) {
      final loggedIn = _cardsListViewModel.isUserAuthenticated == true;

      Future<void> _handleOnPressed() async {
        if (loggedIn) {
          Navigator.pushNamed(context, Routes.cakePayAccountPage);
          return;
        }
        final success = await Navigator.pushNamed<bool>(context, Routes.cakePayWelcomePage);

        if (success == true) await _cardsListViewModel.checkAuth();
      }

      if (!loggedIn || _cardsListViewModel.username == null) {
        return _TrailingIcon(
          asset: 'assets/images/profile.png',
          iconColor: pageIconColor(context) ?? Colors.white,
          onPressed: () async => await _handleOnPressed(),
        );
      }
      final letter = _cardsListViewModel.username!.trim()[0].toUpperCase();
      return IconButton(
        padding: EdgeInsets.zero,
        iconSize: 25,
        onPressed: _handleOnPressed,
        icon: CircleAvatar(
          radius: 12,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget body(BuildContext context) {
    return CakePayCardsPageBody(
        cardsListViewModel: _cardsListViewModel, currentTheme: currentTheme);
  }
}

class CakePayCardsPageBody extends StatefulWidget {
  const CakePayCardsPageBody({
    super.key,
    required CakePayCardsListViewModel cardsListViewModel,
    required this.currentTheme,
  }) : _cardsListViewModel = cardsListViewModel;

  final CakePayCardsListViewModel _cardsListViewModel;
  final ThemeBase currentTheme;

  @override
  State<CakePayCardsPageBody> createState() => _CakePayCardsPageBodyState();
}

class _CakePayCardsPageBodyState extends State<CakePayCardsPageBody> {
  ReactionDisposer? _countryPickerDisposer;

  @override
  void initState() {
    super.initState();
    final viewModel = widget._cardsListViewModel;

    _countryPickerDisposer = when(
      (_) => viewModel.shouldShowCountryPicker,
      () async {
        viewModel.storeInitialFilterStates();

        WidgetsBinding.instance.addPostFrameCallback(
          (_) async {
            await showCountryPicker(context, viewModel);
            if (viewModel.hasFiltersChanged) {
              viewModel.resetLoadingNextPageState();
              viewModel.getVendors();
            }
            viewModel.settingsStore.selectedCakePayCountry = viewModel.selectedCountry;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _countryPickerDisposer?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final isUserAuthenticated = widget._cardsListViewModel.isUserAuthenticated;

      if (isUserAuthenticated == null) return const _Loading();

      if (isUserAuthenticated == false) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _ShopTab(cardsListViewModel: widget._cardsListViewModel),
        );
      }

      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            Expanded(
              child: TabViewWrapper(tabs: const [
                Tab(text: 'My Cards'),
                Tab(text: 'Shop')
              ], views: [
                _MyCardsTab(
                    cardsListViewModel: widget._cardsListViewModel,
                    currentTheme: widget.currentTheme),
                _ShopTab(cardsListViewModel: widget._cardsListViewModel)
              ]),
            )
          ]));
    });
  }
}

Future<void> showFilterWidget(
    BuildContext context, CakePayCardsListViewModel cardsListViewModel) async {
  return showPopUp<void>(
    context: context,
    builder: (BuildContext context) {
      return FilterWidget(filterItems: cardsListViewModel.createFilterItems);
    },
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

class _MyCardsTab extends StatefulWidget {
  const _MyCardsTab({required this.cardsListViewModel, required this.currentTheme});

  final CakePayCardsListViewModel cardsListViewModel;
  final ThemeBase currentTheme;

  @override
  State<_MyCardsTab> createState() => _MyCardsTabState();
}

class _MyCardsTabState extends State<_MyCardsTab> {
  static const double _thumbHeight = 72;

  late final ScrollController _scrollController;
  double _thumbOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        final bg = MediaQuery.of(context).size.height * 0.75;
        setState(() {
          _thumbOffset = max == 0 ? 0 : _scrollController.offset / max * (bg - _thumbHeight);
        });
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final viewModel = widget.cardsListViewModel;
      final cards = viewModel.userCards;

      if (viewModel.userCardState is UserCakePayCardsStateFetching) return const _Loading();
      if (viewModel.userCardState is UserCakePayCardsStateNoCards)
        return Expanded (child: Center(child: Text(S.of(context).no_cards_found)));

      final showThumb = cards.length > 3;
      final bgHeight = MediaQuery.of(context).size.height * 0.75;
      return Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
              child: CakePaySearchBar(
                  initialQuery: viewModel.searchString,
                  onSearch: (String searchText) {},
                  onFilter: () async {})),
          Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      childAspectRatio: 1.25,
                      crossAxisCount: responsiveLayoutUtil.shouldRenderTabletUI ? 3 : 2,
                      crossAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
                      mainAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5),
                  padding: const EdgeInsets.only(left: 2, right: 22),
                  itemCount: cards.length,
                  itemBuilder: (_, i) {
                    final c = cards[i];
                    return UserCardItem(
                      logoUrl: c.cardImageUrl,
                      title: c.name,
                      subTitle: '\$100',
                      backgroundColor:
                          Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                      titleColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                      subtitleColor:
                          Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                      onTap: () => _showCardInfoBottomSheet(context, c, widget.currentTheme),
                    );
                  },
                ),
                if (showThumb)
                  CakeScrollbar(
                    backgroundHeight: bgHeight,
                    thumbHeight: _thumbHeight,
                    fromTop: _thumbOffset,
                    rightOffset: 1,
                    width: 3,
                    backgroundColor:
                        Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(.05),
                    thumbColor:
                        Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(.5),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

Future<void> _showCardInfoBottomSheet(
    BuildContext context, CakePayCard card, ThemeBase currentTheme) async {
  bool isReloadable = false; // TODO: replace with real logic
  if (card.name.toLowerCase().contains('prepaid')) {
    isReloadable = true;
  }
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext bottomSheetContext) {
      return isReloadable
          ? CakePayCardInfoBottomSheet(
              isReloadable: isReloadable,
              titleText: 'Reloadable Card',
              balance: '100 USD',
              howToUse: card.howToUse,
              currentTheme: currentTheme,
              footerType: FooterType.doubleActionButton,
              applyBoxShadow: true,
              contentImage: card.cardImageUrl,
              leftActionButtonKey: const Key('cake_pay_cards_page_reload_card_left_button_key'),
              doubleActionLeftButtonText: 'Archive',
              onLeftActionButtonPressed: () {},
              rightActionButtonKey: const Key('cake_pay_cards_page_reload_card_right_button_key'),
              doubleActionRightButtonText: 'Top Up',
              onRightActionButtonPressed: () {},
              onUpdateBalancePressed: () {})
          : CakePayCardInfoBottomSheet(
              isReloadable: isReloadable,
              titleText: card.name,
              balance: '500 USD',
              howToUse: card.howToUse,
              currentTheme: currentTheme,
              footerType: FooterType.singleActionButton,
              applyBoxShadow: true,
              contentImage: card.cardImageUrl,
              singleActionButtonKey: const Key('cake_pay_cards_page_card_info_bottom_sheet_key'),
              singleActionButtonText: 'Mark As Used',
              onSingleActionButtonPressed: () {},
              onUpdateBalancePressed: () {});
    },
  );
}

class _ShopTab extends StatefulWidget {
  const _ShopTab({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  static const double _thumbHeight = 72;

  late final ScrollController _scroll;
  double _thumbOffset = 0;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()
      ..addListener(() {
        if (!_scroll.hasClients) return;

        final max = _scroll.position.maxScrollExtent;
        final bg = MediaQuery.of(context).size.height * 0.75;
        setState(() {
          _thumbOffset = max == 0 ? 0 : _scroll.offset / max * (bg - _thumbHeight);
        });

        final threshold = 200.0;
        if (_scroll.offset >= max - threshold && !_scroll.position.outOfRange) {
          widget.cardsListViewModel.fetchNextPage();
        }
      });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.cardsListViewModel;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 22, 8),
          child: CakePaySearchBar(
            initialQuery: viewModel.searchString,
            onSearch: (String searchText) {
              if (searchText != viewModel.searchString) {
                viewModel.searchString = searchText;
                viewModel.resetLoadingNextPageState();
                viewModel.getVendors(text: searchText);
              }
            },
            onFilter: () async {
              viewModel.storeInitialFilterStates();
              await showFilterWidget(context, viewModel);
              if (viewModel.hasFiltersChanged) {
                viewModel.resetLoadingNextPageState();
                viewModel.getVendors(text: viewModel.searchString);
              }
            },
            onCountryPick: () async {
              viewModel.storeInitialFilterStates();
              await showCountryPicker(context, viewModel);
              if (viewModel.hasFiltersChanged) {
                viewModel.resetLoadingNextPageState();
                viewModel.getVendors(text: viewModel.searchString);
              }
            },
            selectedCountry: viewModel.selectedCountry,
          ),
        ),
        Observer(builder: (_) {
          final vendors = viewModel.cakePayVendors;

          if (viewModel.vendorsState is! CakePayVendorLoadedState) {
            return Expanded(child: const _Loading());
          }

          if (vendors.isEmpty) return Expanded(child: Center(child: Text(S.of(context).no_cards_found)));

          final loadingMore = viewModel.isLoadingNextPage;
          final showThumb = vendors.length > 3;
          final bgHeight = MediaQuery.of(context).size.height * 0.75;
          return Expanded(
            child: Stack(
              children: [
                GridView.builder(
                  controller: _scroll,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: responsiveLayoutUtil.shouldRenderTabletUI ? 2 : 1,
                    childAspectRatio: 5,
                    crossAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
                    mainAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
                  ),
                  padding: const EdgeInsets.only(left: 2, right: 22),
                  itemCount: vendors.length + (loadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= vendors.length) return const _Loading();
                    final v = vendors[i];
                    return CardItem(
                      logoUrl: v.card?.cardImageUrl,
                      title: v.name,
                      subTitle: v.card?.description ?? '',
                      discount: 0,
                      backgroundColor:
                          Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                      titleColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                      subtitleColor:
                          Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.cakePayBuyCardPage, arguments: [v]),
                    );
                  },
                ),
                if (showThumb)
                  CakeScrollbar(
                    backgroundHeight: bgHeight,
                    thumbHeight: _thumbHeight,
                    fromTop: _thumbOffset,
                    rightOffset: 1,
                    width: 3,
                    backgroundColor:
                        Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(.05),
                    thumbColor:
                        Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(.5),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(
          backgroundColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor,
          ),
        ),
      );
}
