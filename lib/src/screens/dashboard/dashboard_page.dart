import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:cake_wallet/palette.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/balance_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/transactions_page.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator.dart';

class DashboardPage extends BasePage {
  DashboardPage({@required this.walletViewModel});

  @override
  Color get backgroundLightColor => PaletteDark.backgroundColor;

  @override
  Color get backgroundDarkColor => PaletteDark.backgroundColor;

  @override
  Widget middle(BuildContext context) {
    return SyncIndicator(dashboardViewModel: walletViewModel);
  }

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset('assets/images/menu.png',
        color: Colors.white);

    return Container(
      alignment: Alignment.centerRight,
      width: 40,
      child: FlatButton(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        padding: EdgeInsets.all(0),
        onPressed: () async {
          await showDialog<void>(
            builder: (_) => MenuWidget(
              name: walletViewModel.name,
              subname: walletViewModel.subname,
              type: walletViewModel.type),
            context: context);
        },
        child: menuButton
      )
    );
  }

  final DashboardViewModel walletViewModel;
  final sendImage = Image.asset('assets/images/upload.png',
      height: 22.24, width: 24, color: Colors.white);
  final exchangeImage = Image.asset('assets/images/transfer.png',
      height: 24.27, width: 22.25, color: Colors.white);
  final receiveImage = Image.asset('assets/images/download.png',
      height: 22.24, width: 24, color: Colors.white);
  final controller = PageController(initialPage: 0);

  var pages = <Widget>[];
  bool _isEffectsInstalled = false;

  @override
  Widget body(BuildContext context) {

    _setEffects();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return pages[index];
              }
            )
          ),
          Padding(
            padding: EdgeInsets.only(
                bottom: 24
            ),
            child: Observer(
                builder: (_) {
                  return DotsIndicator(
                    dotsCount: pages.length,
                    position: walletViewModel.currentPage,
                    decorator: DotsDecorator(
                      color: PaletteDark.cyanBlue,
                      activeColor: Colors.white,
                      size: Size(6, 6),
                      activeSize: Size(6, 6),
                    ),
                  );
                }
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: 45,
              right: 45,
              bottom: 24
            ),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: ActionButton(
                    image: sendImage,
                    title: S.of(context).send,
                    route: Routes.send,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                Flexible(
                  child: ActionButton(
                    image: exchangeImage,
                    title: S.of(context).exchange,
                    route: Routes.exchange
                  ),
                ),
                Flexible(
                  child: ActionButton(
                    image: receiveImage,
                    title: S.of(context).receive,
                    route: Routes.receive,
                    alignment: Alignment.centerRight,
                  ),
                )
              ],
            ),
          )
        ],
      )
    );
  }

  void _setEffects() {
    if (_isEffectsInstalled) {
      return;
    }

    pages.add(BalancePage(dashboardViewModel: walletViewModel));
    pages.add(TransactionsPage(dashboardViewModel: walletViewModel));

    controller.addListener(() {
      walletViewModel.currentPage = controller.page;
    });

    reaction((_) => walletViewModel.currentPage, (double currentPage) {
      if (controller.page != currentPage) {
        controller.jumpTo(currentPage);
      }
    });

    _isEffectsInstalled = true;
  }
}
