import 'package:cake_wallet/ionia/cake_pay_states.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/filter_widget.dart';
import 'package:cake_wallet/src/widgets/gradient_background.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_item.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_menu.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_filter_modal.dart';
import 'package:cake_wallet/src/widgets/cake_scrollbar.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_gift_cards_list_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';

class CakePayCardsPage extends BasePage {
  CakePayCardsPage(this._cardsListViewModel): searchFocusNode = FocusNode()  {
    _searchController.addListener(() {
      if (_searchController.text != _cardsListViewModel.searchString) {
        _searchDebounce.run(() {
          _cardsListViewModel.searchMerchant(_searchController.text);
        });
      }
    });

    _cardsListViewModel.getVendors();

  }
  final FocusNode searchFocusNode;
  final IoniaGiftCardsListViewModel _cardsListViewModel;

  final _searchDebounce = Debounce(Duration(milliseconds: 500));
  final _searchController = TextEditingController();

  @override
  bool get gradientBackground => true;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) =>
          GradientBackground(scaffold: scaffold);

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => CardMenu();

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).gift_cards,
      style: textMediumSemiBold(
        color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
      ),
    );
  }

  @override
  Widget trailing(BuildContext context) {
    return _TrailingIcon(
      asset: 'assets/images/profile.png',
      onPressed: () => Navigator.pushNamed(context, Routes.ioniaAccountPage),
    );
  }

  @override
  Widget body(BuildContext context) {
    final filterButton = Semantics(
      label: S.of(context).filter_by,
      child: InkWell(
          onTap: () async {
            await showCategoryFilter(context);
            _cardsListViewModel.getVendors();
          },
          child: Container(
            width: 32,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/images/filter.png',
              color: Theme.of(context).extension<FilterTheme>()!.iconColor,
            ),
          )),
    );

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 2, right: 22),
            height: 32,
            child: Row(
              children: [
                Expanded(
                    child: _SearchWidget(
                  controller: _searchController,
                  focusNode: searchFocusNode,
                )),
                SizedBox(width: 10),
                filterButton
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: CakePayCardsPageBody(
              cardsListViewModel: _cardsListViewModel,
            ),
          ),
        ],
      ),
    );
  }

  Future <void> showCategoryFilter(BuildContext context) async {
    return showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return FilterWidget(filterItems: _cardsListViewModel.filterItems);
      },
    );
  }
}

class CakePayCardsPageBody extends StatefulWidget {
  const CakePayCardsPageBody({
    Key? key,
    required this.cardsListViewModel,
  }) : super(key: key);

  final IoniaGiftCardsListViewModel cardsListViewModel;

  @override
  _CakePayCardsPageBodyState createState() => _CakePayCardsPageBodyState();
}

class _CakePayCardsPageBodyState extends State<CakePayCardsPageBody> {
  double get backgroundHeight => MediaQuery.of(context).size.height * 0.75;
  double thumbHeight = 72;
  bool get isAlwaysShowScrollThumb => merchantsList == null ? false : merchantsList.length > 3;

  List<CakePayVendor> get merchantsList => widget.cardsListViewModel.cakePayVendors;

  final _scrollController = ScrollController();

  @override
  void initState() {
    _scrollController.addListener(() {
      final scrollOffsetFromTop = _scrollController.hasClients
          ? (_scrollController.offset / _scrollController.position.maxScrollExtent * (backgroundHeight - thumbHeight))
          : 0.0;
      widget.cardsListViewModel.setScrollOffsetFromTop(scrollOffsetFromTop);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final merchantState = widget.cardsListViewModel.merchantState;
        if (merchantState is CakePayVendorLoadedState) {
        return Stack(children: [
        ListView.separated(
          padding: EdgeInsets.only(left: 2, right: 22),
          controller: _scrollController,
          itemCount: merchantsList.length,
          separatorBuilder: (_, __) => SizedBox(height: 5),
          itemBuilder: (_, index) {
            final vendor = merchantsList[index];
            return CardItem(
              logoUrl: vendor.card?.cardImageUrl,
              onTap: () {
                Navigator.of(context).pushNamed(Routes.CakePayBuyCardPage, arguments: [vendor]);
              },
              title: vendor.name,
              subTitle: vendor.card?.description ?? '',
              backgroundColor: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
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
                backgroundColor: Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(0.05),
                thumbColor: Theme.of(context).extension<FilterTheme>()!.iconColor.withOpacity(0.5),
                fromTop: widget.cardsListViewModel.scrollOffsetFromTop,
              )
            : Offstage()
          ]);
         } 
         return Center(
          child: CircularProgressIndicator(
            backgroundColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor),
          ),
        );
      }
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
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
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
  const _TrailingIcon({required this.asset, this.onPressed});

  final String asset;
  final VoidCallback? onPressed;

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
          splashColor: Colors.transparent,
          iconSize: 25,
          onPressed: onPressed,
          icon: Image.asset(
            asset,
            color: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
          ),
        ),
      ),
    );
  }
}
