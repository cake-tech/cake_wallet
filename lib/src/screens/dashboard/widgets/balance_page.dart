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
      margin: const EdgeInsets.only(top: 20),
       color: Colors.transparent,
        padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
       
        children: [
          Container(
            padding: const EdgeInsets.all(24),

            child: Observer(builder: (_) {
                  return AutoSizeText(
                      dashboardViewModel.balanceViewModel.asset,
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
                })),
            
            
          Card(
            elevation: 10,
            color:Theme.of(context).textTheme.title.decorationColor,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),

             ),
             child: Padding(
               padding: const EdgeInsets.all(30.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Observer(builder: (_) {
                  return Column(
                    children: [
                      Text(
                        '${dashboardViewModel.balanceViewModel.availableBalanceLabel}',
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
                    ],
                  );
                }),

                Observer(builder: (_) {
                  return AutoSizeText(
                      dashboardViewModel.balanceViewModel.availableBalance,
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

                        Observer(builder: (_) {
                  return Column(
                    children: [
                      Text(
                        '${dashboardViewModel.balanceViewModel.availableFiatBalance.toString()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .accentTextTheme
                                .display3
                                .backgroundColor,
                            height: 1),
                      )
                    ],
                  );
                }),

                SizedBox(height: 50,),
                Observer(builder: (_) {
                  return Column(
                    children: [
                      Text(
                        '${dashboardViewModel.balanceViewModel.additionalBalanceLabel}',
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
                    ],
                  );
                }),
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

                Observer(builder: (_) {
                  return Column(
                    children: [
                      Text(
                        '${dashboardViewModel.balanceViewModel.additionalFiatBalance.toString()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .accentTextTheme
                                .display3
                                .backgroundColor,
                            height: 1),
                      )
                    ],
                  );
                }),
               ],
               ),

                 Observer(builder: (_) {
                  return Text(
                    dashboardViewModel.balanceViewModel.currency.toString(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .accentTextTheme
                            .display3
                            .backgroundColor,
                        height: 1),
                  );
                }),
                 ],
               ),
             ),
            )
        ],
      ),
    ),
 
    );
  }
}
