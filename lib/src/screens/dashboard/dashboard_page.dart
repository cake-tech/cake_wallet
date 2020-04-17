import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/wallet_card.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/trade_history_panel.dart';

class DashboardPage extends BasePage {
  final _bodyKey = GlobalKey();

  @override
  ObstructingPreferredSizeWidget appBar(BuildContext context) => null;

  @override
  Widget body(BuildContext context) => DashboardPageBody(key: _bodyKey);
}

class DashboardPageBody extends StatefulWidget {
  DashboardPageBody({Key key}) : super(key: key);

  @override
  DashboardPageBodyState createState() => DashboardPageBodyState();
}

class DashboardPageBodyState extends State<DashboardPageBody> {
  final menuButton = Image.asset('assets/images/menu_button.png');

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [PaletteDark.backgroundStart, PaletteDark.backgroundEnd];

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors
          )
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 14),
              child: Container(
                width: double.infinity,
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 37,
                  width: 37,
                  child: ButtonTheme(
                    minWidth: double.minPositive,
                    child: FlatButton(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        padding: EdgeInsets.all(0),
                        onPressed: () {},
                        child: menuButton),
                  ),
                ),
              )
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, top: 23),
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
