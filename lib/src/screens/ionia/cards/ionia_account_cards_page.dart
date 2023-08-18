
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/card_item.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/themes/extensions/order_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/view_model/ionia/ionia_account_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';

class IoniaAccountCardsPage extends BasePage {
  IoniaAccountCardsPage(this.ioniaAccountViewModel);

  final IoniaAccountViewModel ioniaAccountViewModel;

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).cards,
      style: textLargeSemiBold(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return _IoniaCardTabs(ioniaAccountViewModel);
  }
}

class _IoniaCardTabs extends StatefulWidget {
  _IoniaCardTabs(this.ioniaAccountViewModel);

  final IoniaAccountViewModel ioniaAccountViewModel;

  @override
  _IoniaCardTabsState createState() => _IoniaCardTabsState();
}

class _IoniaCardTabsState extends State<_IoniaCardTabs> with SingleTickerProviderStateMixin {
  _IoniaCardTabsState();

  TabController? _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            width: 230,
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).extension<CakeTextTheme>()!.titleColor
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                25.0,
              ),
            ),
            child: Theme(
              data: ThemeData(primaryTextTheme: TextTheme(bodyLarge: TextStyle(backgroundColor: Colors.transparent))),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    25.0,
                  ),
                  color: Theme.of(context).primaryColor,
                ),
                labelColor: Theme.of(context).extension<OrderTheme>()!.iconColor,
                unselectedLabelColor:
                    Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                tabs: [
                  Tab(
                    text: S.of(context).active,
                  ),
                  Tab(
                    text: S.of(context).redeemed,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Observer(builder: (_) {
              final viewModel = widget.ioniaAccountViewModel;
              return TabBarView(
                controller: _tabController,
                children: [
                  _IoniaCardListView(
                    emptyText: S.of(context).gift_card_balance_note,
                    merchList: viewModel.activeMechs,
                    isLoading: viewModel.merchantState is IoniaLoadingMerchantState,
                    onTap: (giftCard) {
                      Navigator.pushNamed(
                        context,
                        Routes.ioniaGiftCardDetailPage,
                        arguments: [giftCard])
                      .then((_) => viewModel.updateUserGiftCards());
                    }),
                  _IoniaCardListView(
                    emptyText: S.of(context).gift_card_redeemed_note,
                    merchList: viewModel.redeemedMerchs,
                    isLoading: viewModel.merchantState is IoniaLoadingMerchantState,
                    onTap: (giftCard) {
                      Navigator.pushNamed(
                        context,
                        Routes.ioniaGiftCardDetailPage,
                        arguments: [giftCard])
                      .then((_) => viewModel.updateUserGiftCards());
                    }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _IoniaCardListView extends StatelessWidget {
  _IoniaCardListView({
    Key? key,
    required this.emptyText,
    required this.merchList,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  final String emptyText;
  final List<IoniaGiftCard> merchList;
  final void Function(IoniaGiftCard giftCard) onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return Center(
        child: CircularProgressIndicator(
          backgroundColor: Theme.of(context).extension<DashboardPageTheme>()!.textColor,
          valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).extension<ExchangePageTheme>()!.firstGradientBottomPanelColor),
        ),
      );
    }
    return merchList.isEmpty
        ? Center(
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: textSmall(
                color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
              ),
            ),
          )
        : ListView.builder(
            itemCount: merchList.length,
            itemBuilder: (context, index) {
              final merchant = merchList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CardItem(
                  onTap: () => onTap?.call(merchant),
                  title: merchant.legalName,
                  backgroundColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor
                      .withOpacity(0.1),
                  discount: 0,
                  hideBorder: true,
                  discountBackground: AssetImage('assets/images/red_badge_discount.png'),
                  titleColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  subtitleColor: Theme.of(context).hintColor,
                  subTitle: '',
                  logoUrl: merchant.logoUrl,
                ),
              );
            },
          );
  }
}
