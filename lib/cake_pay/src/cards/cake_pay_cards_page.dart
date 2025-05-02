import 'package:cake_wallet/cake_pay/src/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_search_bar_widget.dart';
import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/cake_pay/src/widgets/card_item.dart';
import 'package:cake_wallet/cake_pay/src/widgets/card_menu.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
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
        reaction((_) => _cardsListViewModel.shouldShowCountryPicker,
            (bool shouldShowCountryPicker) async {
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

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(children: [
          Expanded(child: CakePayCardsPageBody(cardsListViewModel: _cardsListViewModel))
        ]));
  }
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

class CakePayCardsPageBody extends StatefulWidget {
  CakePayCardsPageBody({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  _CakePayCardsPageBodyState createState() => _CakePayCardsPageBodyState(cardsListViewModel);
}

class _CakePayCardsPageBodyState extends State<CakePayCardsPageBody>
    with SingleTickerProviderStateMixin {
  _CakePayCardsPageBodyState(this._cardsListViewModel);

  final CakePayCardsListViewModel _cardsListViewModel;
  late TabController _tabController;

  double thumbHeight = 72;

  double get backgroundHeight => MediaQuery.of(context).size.height * 0.75;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            splashFactory: NoSplash.splashFactory,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(
              fontSize: 18,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              color: Theme.of(context).appBarTheme.titleTextStyle!.color,
            ),
            unselectedLabelStyle: TextStyle(
                fontSize: 18,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).appBarTheme.titleTextStyle!.color?.withOpacity(0.5)),
            labelColor: Theme.of(context).appBarTheme.titleTextStyle!.color,
            indicatorColor: Theme.of(context).appBarTheme.titleTextStyle!.color,
            indicatorPadding: EdgeInsets.zero,
            labelPadding: EdgeInsets.only(right: 24),
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            padding: EdgeInsets.zero,
            tabs: const [
              Tab(text: 'My Cards'),
              Tab(text: 'Shop'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabController, children: [
            _MyCardsTab(cardsListViewModel: _cardsListViewModel),
            _ShopTab(cardsListViewModel: _cardsListViewModel),
          ]),
        ),
      ],
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

class _MyCardsTab extends StatefulWidget {
  const _MyCardsTab({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  State<_MyCardsTab> createState() => _MyCardsTabState();
}

class _MyCardsTabState extends State<_MyCardsTab> {
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
      });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final viewModel = widget.cardsListViewModel;
      final cards = viewModel.userCards;

      if (viewModel.userCardState is UserCakePayCardsStateFetching) return const _Loading();

      if (cards.isEmpty) return Center(child: Text(S.of(context).no_cards_found));

      final showThumb = cards.length > 3;
      final bgHeight = MediaQuery.of(context).size.height * 0.75;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
            child: CakePaySearchBar(
              cardsListViewModel: viewModel,
              showCountryPicker: false,
            ),
          ),
          Expanded(
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
                  itemCount: cards.length,
                  itemBuilder: (_, i) {
                    final c = cards[i];
                    return CardItem(
                      logoUrl: c.cardImageUrl,
                      title: c.name,
                      subTitle: c.description ?? '',
                      discount: 0,
                      backgroundColor:
                          Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                      titleColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
                      subtitleColor:
                          Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
                      onTap: () {}, // open card details if needed
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
    return Observer(builder: (_) {
      final viewModel = widget.cardsListViewModel;
      final vendors = viewModel.cakePayVendors;

      if (viewModel.vendorsState is! CakePayVendorLoadedState) return const _Loading();
      if (vendors.isEmpty) return Center(child: Text(S.of(context).no_cards_found));

      final loadingMore = viewModel.isLoadingNextPage;
      final showThumb = vendors.length > 3;
      final bgHeight = MediaQuery.of(context).size.height * 0.75;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 8, 22, 8),
            child: CakePaySearchBar(
              cardsListViewModel: viewModel,
            ),
          ),
          Expanded(
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
          ),
        ],
      );
    });
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
