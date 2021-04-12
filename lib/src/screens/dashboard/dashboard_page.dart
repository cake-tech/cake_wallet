import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/balance_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/address_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/transactions_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class DashboardPage extends BasePage {
  DashboardPage({
    @required this.walletViewModel,
    @required this.addressListViewModel,
  });

  @override
  Color get backgroundLightColor => currentTheme.type == ThemeType.bright
      ? Colors.transparent : Colors.white;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).accentColor,
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor,
          ], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  bool get resizeToAvoidBottomPadding => false;

  @override
  Widget get endDrawer => MenuWidget(walletViewModel);

  @override
  Widget middle(BuildContext context) {
    return SyncIndicator(dashboardViewModel: walletViewModel);
  }

  @override
  Widget trailing(BuildContext context) {
    final menuButton =
        Image.asset('assets/images/menu.png',
            color: Theme.of(context).accentTextTheme.display3.backgroundColor);

    return Container(
        alignment: Alignment.centerRight,
        width: 40,
        child: FlatButton(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            padding: EdgeInsets.all(0),
            onPressed: () => onOpenEndDrawer(),
            child: menuButton));
  }

  final DashboardViewModel walletViewModel;
  final WalletAddressListViewModel addressListViewModel;
  final controller = PageController(initialPage: 1);

  var pages = <Widget>[];
  bool _isEffectsInstalled = false;

  @override
  Widget body(BuildContext context) {
    final sendImage = Image.asset('assets/images/upload.png',
        height: 22.24, width: 24,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    final exchangeImage = Image.asset('assets/images/transfer.png',
        height: 24.27, width: 22.25,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    final buyImage = Image.asset('assets/images/coins.png',
        height: 22.24, width: 24,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    _setEffects();

    return SafeArea(
        child: Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Expanded(
            child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                itemBuilder: (context, index) => pages[index])),
        Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: SmoothPageIndicator(
              controller: controller,
              count: pages.length,
              effect: ColorTransitionEffect(
                  spacing: 6.0,
                  radius: 6.0,
                  dotWidth: 6.0,
                  dotHeight: 6.0,
                  dotColor: Theme.of(context).indicatorColor,
                  activeDotColor: Theme.of(context).accentTextTheme.display1
                      .backgroundColor),
            )),
        Container(
          padding: EdgeInsets.only(left: 45, right: 45, bottom: 24),
          child: Observer(builder: (_) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ActionButton(
                  image: sendImage,
                  title: S.of(context).send,
                  route: Routes.send),
              ActionButton(
                  image: exchangeImage,
                  title: S.of(context).exchange,
                  route: Routes.exchange),
              if (walletViewModel.type == WalletType.bitcoin) ActionButton(
                image: buyImage,
                title: S.of(context).buy,
                onClick: () {
                  Navigator.of(context).pushNamed(Routes.preOrder);
                },
              ),
            ],
          )),
        )
      ],
    ));
  }

  void _setEffects() {
    if (_isEffectsInstalled) {
      return;
    }

    pages.add(AddressPage(addressListViewModel: addressListViewModel));
    pages.add(BalancePage(dashboardViewModel: walletViewModel));
    pages.add(TransactionsPage(dashboardViewModel: walletViewModel));

    _isEffectsInstalled = true;
  }
}
