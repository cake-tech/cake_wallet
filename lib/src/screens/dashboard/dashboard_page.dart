import 'dart:async';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/yat/yat_popup.dart';
import 'package:cake_wallet/src/screens/yat_emoji_id.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
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
import 'package:mobx/mobx.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:cake_wallet/main.dart';
import 'package:cake_wallet/router.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends BasePage {
  DashboardPage({
    @required this.walletViewModel,
    @required this.addressListViewModel,
  });

  @override
  Color get backgroundLightColor =>
      currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;

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
  bool get resizeToAvoidBottomInset => false;

  @override
  Widget get endDrawer => MenuWidget(walletViewModel);

  @override
  Widget middle(BuildContext context) {
    return SyncIndicator(dashboardViewModel: walletViewModel);
  }

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset('assets/images/menu.png',
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
  StreamSubscription<bool> _onInactiveSub;

  @override
  Widget body(BuildContext context) {
    final sendImage = Image.asset('assets/images/upload.png',
        height: 22.24,
        width: 24,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    final exchangeImage = Image.asset('assets/images/transfer.png',
        height: 24.27,
        width: 22.25,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    final buyImage = Image.asset('assets/images/coins.png',
        height: 22.24,
        width: 24,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    final sellImage = Image.asset('assets/images/restore_wallet_image.png',
        height: 22.24,
        width: 24,
        color: Theme.of(context).accentTextTheme.display3.backgroundColor);
    _setEffects(context);

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
                  activeDotColor: Theme.of(context)
                      .accentTextTheme
                      .display1
                      .backgroundColor),
            )),
        Container(
          padding: EdgeInsets.only(left: 45, right: 45, bottom: 24),
          child: Row(
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
              ActionButton(
                  image: buyImage,
                  title: S.of(context).buy,
                  onClick: () async =>
                    await _onClickBuyButton(context),
              ),
              ActionButton(
                  image: sellImage,
                  title: 'Sell',
                  onClick: () async =>
                    await _onClickSellButton(context),
              ),
            ],
          ),
        )
      ],
    ));
  }

  void _setEffects(BuildContext context) async {
    if (_isEffectsInstalled) {
      return;
    }

    pages.add(AddressPage(addressListViewModel: addressListViewModel,
              walletViewModel: walletViewModel));
    pages.add(BalancePage(dashboardViewModel: walletViewModel));
    pages.add(TransactionsPage(dashboardViewModel: walletViewModel));
    _isEffectsInstalled = true;
    
    if (walletViewModel.shouldShowYatPopup) {
      await Future<void>.delayed(Duration(seconds: 1));
    
      if (currentRouteSettings.name == Routes.preSeed
          || currentRouteSettings.name == Routes.seed) {
        return;
      }

      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return YatPopup(
                dashboardViewModel: walletViewModel,
                onClose: () => Navigator.of(context).pop());
          });
      walletViewModel.furtherShowYatPopup(false);
    }

    autorun((_) async {
      if (!walletViewModel.isOutdatedElectrumWallet) {
        return;
      }

      await Future<void>.delayed(Duration(seconds: 1));
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: S.of(context).pre_seed_title,
                alertContent:
                    S.of(context).outdated_electrum_wallet_description,
                buttonText: S.of(context).understand,
                buttonAction: () => Navigator.of(context).pop());
          });
    });

    var needToPresentYat = false;
    var isInactive = false;

    _onInactiveSub = rootKey.currentState.isInactive.listen((inactive) {
      isInactive = inactive;

      if (needToPresentYat) {
        Future<void>.delayed(Duration(milliseconds: 500)).then((_) {
          showPopUp<void>(
            context: navigatorKey.currentContext,
            builder: (_) => YatEmojiId(walletViewModel.yatStore.emoji));
          needToPresentYat = false;
        });
      }
    });

    walletViewModel.yatStore.emojiIncommingStream.listen((String emoji) {
      if (!_isEffectsInstalled || emoji.isEmpty) {
        return;
      }

      needToPresentYat = true;
    });
  }

  Future<void> _onClickBuyButton(BuildContext context) async {
    final walletType = walletViewModel.type;

    switch (walletType) {
      case WalletType.bitcoin:
        Navigator.of(context).pushNamed(Routes.preOrder);
        break;
      case WalletType.litecoin:
        Navigator.of(context).pushNamed(Routes.preOrder);
        break;
      default:
        await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).buy,
                  alertContent: S.of(context).buy_alert_content,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
    }
  }

  Future<void> _onClickSellButton(BuildContext context) async {
    final walletType = walletViewModel.type;

    switch (walletType) {
      case WalletType.bitcoin:
        final moonPaySellProvider = MoonPaySellProvider();
        final uri = await moonPaySellProvider.requestUrl(
          currency: walletViewModel.wallet.currency,
          refundWalletAddress: walletViewModel.wallet.walletAddresses.address);
        await launch(uri);
        break;
      default:
        await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).buy,
                  alertContent: S.of(context).buy_alert_content,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.of(context).pop());
            });
    }
  }
}
