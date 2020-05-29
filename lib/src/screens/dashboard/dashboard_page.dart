import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/wallet_card.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/trade_history_panel.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/menu_widget.dart';

class DashboardPage extends StatelessWidget {
  final _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) => DashboardPageBody(key: _bodyKey);
}

class DashboardPageBody extends StatefulWidget {
  DashboardPageBody({Key key}) : super(key: key);

  @override
  DashboardPageBodyState createState() => DashboardPageBodyState();
}

class DashboardPageBodyState extends State<DashboardPageBody> {

  @override
  Widget build(BuildContext context) {
    final menuButton = Image.asset('assets/images/header.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );

    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).primaryColor
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight
              )
          ),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(top: 10, right: 10),
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44,
                  width: 44,
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
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 20, top: 20),
                child: WalletCard(),
              ),
              SizedBox(
                height: 28,
              ),
              Expanded(child: TradeHistoryPanel())
            ],
          ),
        ),
      ),
    );
  }
}
