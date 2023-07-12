import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
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

class IoniaManageCardsPage extends BasePage {
  IoniaManageCardsPage(this._cardsListViewModel): searchFocusNode = FocusNode()  {
    _searchController.addListener(() {
      if (_searchController.text != _cardsListViewModel.searchString) {
        _searchDebounce.run(() {
          _cardsListViewModel.searchMerchant(_searchController.text);
        });
      }
    });

    _cardsListViewModel.getMerchants();

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
            _cardsListViewModel.getMerchants();
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
            child: IoniaManageCardsPageBody(
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
        return IoniaFilterModal(
          ioniaGiftCardsListViewModel: _cardsListViewModel,
        );
      },
    );
  }
}

class IoniaManageCardsPageBody extends StatefulWidget {
  const IoniaManageCardsPageBody({
    Key? key,
    required this.cardsListViewModel,
  }) : super(key: key);

  final IoniaGiftCardsListViewModel cardsListViewModel;

  @override
  _IoniaManageCardsPageBodyState createState() => _IoniaManageCardsPageBodyState();
}

class _IoniaManageCardsPageBodyState extends State<IoniaManageCardsPageBody> {
  double get backgroundHeight => MediaQuery.of(context).size.height * 0.75;
  double thumbHeight = 72;
  bool get isAlwaysShowScrollThumb => merchantsList == null ? false : merchantsList.length > 3;

  List<IoniaMerchant> get merchantsList => widget.cardsListViewModel.ioniaMerchants;

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
        if (merchantState is IoniaLoadedMerchantState) {
        return Stack(children: [
        ListView.separated(
          padding: EdgeInsets.only(left: 2, right: 22),
          controller: _scrollController,
          itemCount: merchantsList.length,
          separatorBuilder: (_, __) => SizedBox(height: 4),
          itemBuilder: (_, index) {
            final merchant = merchantsList[index];
            return CardItem(
              logoUrl: merchant.logoUrl,
              onTap: () {
                Navigator.of(context).pushNamed(Routes.ioniaBuyGiftCardPage, arguments: [merchant]);
              },
              title: merchant.legalName,
              subTitle: merchant.avaibilityStatus,
              backgroundColor: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
              titleColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
              subtitleColor: Theme.of(context).extension<BalancePageTheme>()!.labelTextColor,
              discount: merchant.discount,
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
