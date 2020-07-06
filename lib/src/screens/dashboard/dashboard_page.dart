import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/view_model/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/wallet_card.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/trade_history_panel.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';

class DashboardPage extends BasePage {
  DashboardPage({@required this.walletViewModel});

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: scaffold);

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset('assets/images/header.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return Container(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 24,
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
            child: menuButton),
      ),
    );
  }

  final DashboardViewModel walletViewModel;
  final sendImage = Image.asset('assets/images/send.png');
  final exchangeImage = Image.asset('assets/images/exchange.png');
  final buyImage = Image.asset('assets/images/coins.png');

  @override
  Widget body(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final transactionListMinHeight =
          constraints.heightConstraints().maxHeight - 345 - 32;

      return SingleChildScrollView(
          child: Column(children: [
        Container(
            height: 345,
            child: Column(children: [
              Padding(
                  padding: EdgeInsets.only(left: 24, top: 10),
                  child: WalletCard(walletVM: walletViewModel)),
              Container(
                padding: EdgeInsets.only(left: 44, right: 44, top: 32),
                child: Row(
                  children: <Widget>[
                    Flexible(
                        child: actionButton(
                            context: context,
                            image: sendImage,
                            title: S.of(context).send,
                            route: Routes.send)),
                    Flexible(
                        child: actionButton(
                            context: context,
                            image: exchangeImage,
                            title: S.of(context).exchange,
                            route: Routes.exchange)),
                  ],
                ),
              )
            ])),
        SizedBox(height: 32),
        ConstrainedBox(
            constraints: BoxConstraints(minHeight: transactionListMinHeight),
            child: TradeHistoryPanel(dashboardViewModel: walletViewModel)),
//                  Column(children: [
//                    Text('1'),
//                    Text('2')
//                  ])
      ]));
    });
  }
}

Widget actionButton(
    {BuildContext context,
    @required Image image,
    @required String title,
    @required String route}) {
  return Container(
    width: MediaQuery.of(context).size.width,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            if (route.isNotEmpty) {
              Navigator.of(context, rootNavigator: true).pushNamed(route);
            }
          },
          child: Container(
            height: 48,
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryTextTheme.subhead.color,
                shape: BoxShape.circle),
            child: image,
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(140, 153, 201,
                    0.8) // Theme.of(context).primaryTextTheme.caption.color
                ),
          ),
        )
      ],
    ),
  );
}
