import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BalancePage extends StatelessWidget {
  BalancePage({@required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () =>
      dashboardViewModel.balanceViewModel.isReversing =
      !dashboardViewModel.balanceViewModel.isReversing,
      onLongPressUp: () =>
      dashboardViewModel.balanceViewModel.isReversing =
      !dashboardViewModel.balanceViewModel.isReversing,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.all(24),
        child: Observer(builder: (BuildContext context) {
          if (dashboardViewModel.balanceViewModel.hasMultiBalance) {
            return ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => StandardListSeparator(padding: EdgeInsets.only(left: 24)),
                  itemCount: dashboardViewModel.balanceViewModel.formattedBalances.length,
                  itemBuilder: (__, index) {
                    final balance = dashboardViewModel.balanceViewModel.formattedBalances.elementAt(index);
                    final cur = balance.asset.toString();
                    
                    return Container(
                      padding: EdgeInsets.only(left: 5, right: 15, bottom: 15, top: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).buttonColor,
                              border: Border.all(color: Theme.of(context).buttonColor),
                              borderRadius: BorderRadius.all(Radius.circular(20))
                            ),
                            padding: EdgeInsets.only(left: 12, right: 12, top: 7, bottom: 7),
                            child: Text(
                              '${cur.toString()}',
                              style: TextStyle(
                                fontSize: 18,
                                color:  Theme.of(context).accentTextTheme.display3.backgroundColor))),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${balance.additionalBalance}',
                              style: TextStyle(
                                fontSize: 22,
                                color:  Theme.of(context).accentTextTheme.display3.backgroundColor)),
                            Text(
                              'Full balance ${balance.fiatAdditionalBalance}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).accentTextTheme.display2.backgroundColor)),
                          Container(height: 5),
                          Text(
                              '${balance.availableBalance}',
                              style: TextStyle(
                                fontSize: 22,
                                color:  Theme.of(context).accentTextTheme.display3.backgroundColor)),
                          Text(
                              'Available balance ${balance.fiatAvailableBalance}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).accentTextTheme.display2.backgroundColor)),
                        ],)
                      ]));
                  });
          }
          
          return Column(
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
          );

        }),
      ),
    );
  }
}
