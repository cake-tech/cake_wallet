import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BalancePage extends StatelessWidget {
  BalancePage({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
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
                  color: Theme.of(context)
                      .accentTextTheme
                      .display2
                      .backgroundColor,
                  height: 1),
            );
          }),
          SizedBox(height: 10),
          Observer(builder: (_) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    '${dashboardViewModel.balanceViewModel.availableBalanceLabel} (${dashboardViewModel.balanceViewModel.availableFiatBalance.toString()})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .accentTextTheme
                            .display2
                            .backgroundColor,
                        height: 1),
                  )
                )
              ],
            );
          }),
          SizedBox(height: 10),
          Observer(builder: (_) {
            return AutoSizeText(
                dashboardViewModel.balanceViewModel.availableBalance,
                style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .accentTextTheme
                        .display3
                        .backgroundColor,
                    height: 1),
                maxLines: 1,
                textAlign: TextAlign.center);
          }),
          SizedBox(height: 10),
          Observer(builder: (_) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    '${dashboardViewModel.balanceViewModel.additionalBalanceLabel} (${dashboardViewModel.balanceViewModel.additionalFiatBalance.toString()})',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .accentTextTheme
                            .display2
                            .backgroundColor,
                        height: 1),
                  )
                )
              ],
            );
          }),
          SizedBox(height: 10),
          Observer(builder: (_) {
            return AutoSizeText(
                dashboardViewModel.balanceViewModel.additionalBalance
                    .toString(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .accentTextTheme
                        .display3
                        .backgroundColor,
                    height: 1),
                maxLines: 1,
                textAlign: TextAlign.center);
          }),
        ],
      ),
    );
  }
}
