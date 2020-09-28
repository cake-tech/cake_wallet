import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BalancePage extends StatelessWidget {
  BalancePage({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Observer(builder: (_) {
            return Text(
              dashboardViewModel.balanceViewModel.currency.toString(),
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).indicatorColor,
                  height: 1),
            );
          }),
          SizedBox(height: 10),
          Observer(builder: (_) {
            return Text(dashboardViewModel.balanceViewModel.cryptoBalance,
                style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1),
                textAlign: TextAlign.center);
          }),
          SizedBox(height: 10),
          Observer(builder: (_) {
            return Text(dashboardViewModel.balanceViewModel.fiatBalance,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).indicatorColor,
                    height: 1),
                textAlign: TextAlign.center);
          }),
        ],
      ),
    );
  }
}
