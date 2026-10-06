import 'package:cake_wallet/cake_pay/src/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_user_card.dart';
import 'package:cake_wallet/cake_pay/src/models/cake_pay_voucher.dart';
import 'package:cake_wallet/cake_pay/src/widgets/cake_pay_search_bar_widget.dart';
import 'package:cake_wallet/cake_pay/src/widgets/user_card_item.dart';
import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/keyboard_hide_overlay.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/cake_pay/src/widgets/card_item.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/cake_pay_card_info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/tab_view_wrapper_widget.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
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
        color: titleColor(context),
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            letter,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget body(BuildContext context) {
    return KeyboardHideOverlay(
        child:
            CakePayCardsPageBody(cardsListViewModel: _cardsListViewModel, titleColor: titleColor));
  }
}

class CakePayCardsPageBody extends StatefulWidget {
  const CakePayCardsPageBody({
    super.key,
    required CakePayCardsListViewModel cardsListViewModel,
    required this.titleColor,
  }) : _cardsListViewModel = cardsListViewModel;

  final CakePayCardsListViewModel _cardsListViewModel;
  final Color? Function(BuildContext) titleColor;

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

      if (isUserAuthenticated == false || !FeatureFlag.isCakePayRedemptionFlowEnabled) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _ShopTab(cardsListViewModel: widget._cardsListViewModel),
        );
      }

      final titleColor = widget.titleColor(context);

      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(children: [
            Expanded(
              child: TabViewWrapper(
                  labelStyle: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                      color: titleColor?.withAlpha(150) ?? Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w400),
                  indicatorColor: titleColor,
                  tabs: const [
                    Tab(text: 'My Cards'),
                    Tab(text: 'Shop')
                  ],
                  views: [
                    _MyCardsTab(
                      cardsListViewModel: widget._cardsListViewModel,
                    ),
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
  const _MyCardsTab({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  State<_MyCardsTab> createState() => _MyCardsTabState();
}

class _MyCardsTabState extends State<_MyCardsTab> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.cardsListViewModel.searchMyCardsString,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.cardsListViewModel;
    return Observer(builder: (_) {
      return Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(2, 6, 0, 6),
              child: CakePaySearchBar(
                initialQuery: viewModel.searchMyCardsString,
                controller: _searchController,
                onSearch: viewModel.setMyCardsQuery,
                onFilter: () async {}, // TODO: implement filter
              )),
          Expanded(
            child: Observer(builder: (_) {
              final cards = viewModel.filteredUserCards;
              if (viewModel.userCardState is UserCakePayCardsStateInitial ||
                  viewModel.userCardState is UserCakePayCardsStateFetching) {
                return const _Loading();
              }

              if (viewModel.userCardState is UserCakePayCardsStateNoCards)
                return Center(child: Text(S.of(context).no_cards_found));

              final cardsState = viewModel.userCardState;

              if (cardsState is UserCakePayCardsStateFailure) {
                return Center(child: Text(cardsState.error, textAlign: TextAlign.center));
              }

              final showThumb = cards.length > 6;
              final userCardsList = Stack(
                children: [
                  GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        childAspectRatio: 1.25,
                        crossAxisCount: responsiveLayoutUtil.shouldRenderTabletUI ? 3 : 2,
                        crossAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
                        mainAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5),
                    padding: EdgeInsets.only(left: 2, right: showThumb ? 10 : 22),
                    itemCount: cards.length,
                    itemBuilder: (_, i) {
                      final card = cards[i];
                      return UserCardItem(
                        logoUrl: card.imageUrl,
                        title: card.name,
                        subTitle: card.valueLabel,
                        onTap: () => _redeemAndShowCard(context, viewModel, card),
                      );
                    },
                  ),
                ],
              );

              return RefreshIndicator(
                key: const ValueKey('cake_pay_my_cards_tab_refresh_indicator_key'),
                onRefresh: () => viewModel.getUserCards(showLoading: false),
                child: showThumb
                    ? Scrollbar(
                        key: ValueKey('cake_pay_my_cards_tab_scrollbar_key'),
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: userCardsList,
                      )
                    : userCardsList,
              );
            }),
          ),
        ],
      );
    });
  }
}

Future<void> _redeemAndShowCard(
  BuildContext context,
  CakePayCardsListViewModel viewModel,
  CakePayUserCard card,
) async {
  final state = await viewModel.redeem(card);
  if (!context.mounted) {
    return;
  }

  switch (state) {
    case CakePayRedemptionStateSuccess():
      await _showCardInfoBottomSheet(context, card, state.voucher);
    case CakePayRedemptionStateBlocked():
      await _showRedemptionMessage(context, state.message);
    case CakePayRedemptionStateFailure():
      await _showRedemptionMessage(context, state.error);
  }
}

Future<void> _showRedemptionMessage(BuildContext context, String message) => showPopUp<void>(
      context: context,
      builder: (context) => AlertWithOneAction(
        alertTitle: 'Cake Pay',
        alertContent: message,
        buttonText: S.of(context).ok,
        buttonAction: () => Navigator.of(context).pop(),
      ),
    );

Future<void> _showCardInfoBottomSheet(
  BuildContext context,
  CakePayUserCard card,
  CakePayVoucher voucher,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (bottomSheetContext) => CakePayCardInfoBottomSheet(
      titleText: card.name,
      balance: card.valueLabel,
      cardNumber: voucher.primaryValue,
      cardNumberLabel: switch (voucher.primaryValueKind) {
        CakePayVoucherValueKind.cardNumber => S.of(bottomSheetContext).gift_card_number,
        CakePayVoucherValueKind.code => S.of(bottomSheetContext).gift_card_code,
        CakePayVoucherValueKind.redemptionLink => S.of(bottomSheetContext).redemption_link,
      },
      pin: voucher.pin,
      howToUse: voucher.redemptionInstructions,
      footerType: FooterType.singleActionButton,
      singleActionButtonKey: const Key('cake_pay_cards_page_card_info_bottom_sheet_close_key'),
      singleActionButtonText: S.of(bottomSheetContext).close,
      onSingleActionButtonPressed: () => Navigator.of(bottomSheetContext).pop(),
      applyBoxShadow: true,
      contentImage: card.imageUrl,
    ),
  );
}

class _ShopTab extends StatefulWidget {
  const _ShopTab({required this.cardsListViewModel});

  final CakePayCardsListViewModel cardsListViewModel;

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()
      ..addListener(() {
        if (!_scroll.hasClients) return;
        final max = _scroll.position.maxScrollExtent;

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
          padding: const EdgeInsets.fromLTRB(2, 6, 0, 6),
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
        Expanded(
          child: Observer(builder: (_) {
            final vendors = viewModel.cakePayVendors;

            if (viewModel.vendorsState is! CakePayVendorLoadedState) {
              return const _Loading();
            }

            if (vendors.isEmpty) return Center(child: Text(S.of(context).no_cards_found));

            final loadingMore = viewModel.isLoadingNextPage;
            final showThumb = vendors.length > 3;
            final cardsList = Stack(
              children: [
                GridView.builder(
                  controller: _scroll,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: responsiveLayoutUtil.shouldRenderTabletUI ? 2 : 1,
                      childAspectRatio: 5,
                      crossAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5,
                      mainAxisSpacing: responsiveLayoutUtil.shouldRenderTabletUI ? 10 : 5),
                  padding: EdgeInsets.only(left: 2, right: showThumb ? 10 : 22),
                  itemCount: vendors.length + (loadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= vendors.length) return const _Loading();
                    final vendor = vendors[i];
                    return CardItem(
                      logoUrl: vendor.card?.cardImageUrl,
                      title: vendor.name,
                      subTitle: vendor.card?.description ?? '',
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          Routes.cakePayBuyCardPage,
                          arguments: [vendor],
                        );
                        await viewModel.checkAuth();
                        await viewModel.getUserCards(showLoading: false);
                      },
                    );
                  },
                ),
              ],
            );
            return showThumb
                ? Scrollbar(
                    key: ValueKey('cake_pay_shop_tab_scrollbar_key'),
                    thumbVisibility: true,
                    trackVisibility: true,
                    controller: _scroll,
                    child: cardsList,
                  )
                : cardsList;
          }),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Center(
        child: CircularProgressIndicator(),
      );
}
