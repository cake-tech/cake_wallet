import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/wallet_card.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/trade_history_panel.dart';

class DashboardPage extends BasePage {
  final _bodyKey = GlobalKey();

  @override
  Color get backgroundColor => PaletteDark.mainBackgroundColor;

  @override
  Widget trailing(BuildContext context) {
    final menuButton = Image.asset('assets/images/header.png');

    return SizedBox(
      height: 37,
      width: 37,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          onPressed: () async {
            await showDialog<void>(
                builder: (_) => MenuWidget(),
                context: context
            );
          },
          child: menuButton),
      ),
    );
  }

  @override
  Widget body(BuildContext context) => DashboardPageBody(key: _bodyKey);
}

class DashboardPageBody extends StatefulWidget {
  DashboardPageBody({Key key}) : super(key: key);

  @override
  DashboardPageBodyState createState() => DashboardPageBodyState();
}

class DashboardPageBodyState extends State<DashboardPageBody> {

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Container(
        color: PaletteDark.mainBackgroundColor,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 20, top: 10),
              child: WalletCard(),
            ),
            SizedBox(
              height: 28,
            ),
            Expanded(child: TradeHistoryPanel())
          ],
        ),
      ),
    );
  }
}
