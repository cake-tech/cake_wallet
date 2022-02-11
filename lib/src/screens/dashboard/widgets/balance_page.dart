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
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(left: 24,),
            margin: const EdgeInsets.only(bottom: 16),
            child: Observer(builder: (_) {
                  return AutoSizeText(
                      dashboardViewModel.balanceViewModel.asset,
                      style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .accentTextTheme
                              .display3
                              .backgroundColor,
                          height: 1),
                      maxLines: 1,
                      textAlign: TextAlign.center);
                })),
           
          ClipRRect(
             child:Container(
               height: 199,
               width: 343,
               decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  color:Theme.of(context).textTheme.title.backgroundColor
                ),
               child: Container(
                 margin: const EdgeInsets.only(top: 16, bottom: 24, left: 24, right: 24),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         SizedBox(height: 8,),
                          Observer(builder: (_) {
                    return Column(
                      children: [
                        Text(
                          '${dashboardViewModel.balanceViewModel.availableBalanceLabel}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .display2
                                  .backgroundColor,
                              height: 1),
                        )
                      ],
                    );
                  }),
                  SizedBox(height: 4,),
                  Observer(builder: (_) {
                    return AutoSizeText(
                        dashboardViewModel.balanceViewModel.availableBalance,
                        style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context)
                                .accentTextTheme
                                .display3
                                .backgroundColor,
                            height: 1),
                        maxLines: 1,
                        textAlign: TextAlign.center);
                  }),
                  SizedBox(height: 2,),
                   Observer(builder: (_) {
                    return Column(
                      children: [
                        Text(
                          '${dashboardViewModel.balanceViewModel.availableFiatBalance.toString()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .display3
                                  .backgroundColor,
                              height: 1),
                        )
                      ],
                    );
                  }),

                  SizedBox(height: 24,),

                  Observer(builder: (_) {
                    return Column(
                      children: [
                        Text(
                          '${dashboardViewModel.balanceViewModel.additionalBalanceLabel}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                             fontSize: 12,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .accentTextTheme
                                  .display2
                                  .backgroundColor,
                              height: 1),
                        )
                      ],
                    );
                  }),
                  SizedBox(height: 4,),
                  Observer(builder: (_) {
                    return AutoSizeText(
                        dashboardViewModel.balanceViewModel.additionalBalance
                            .toString(),
                        style: TextStyle(
                           fontSize: 24,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context)
                                .accentTextTheme
                                .display3
                                .backgroundColor,
                            height: 1),
                        maxLines: 1,
                        textAlign: TextAlign.center);
                  }),
                  SizedBox(height: 2,),
                  Observer(builder: (_) {
                    return Column(
                      children: [
                        Text(
                          '${dashboardViewModel.balanceViewModel.additionalFiatBalance.toString()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                               fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w500,
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
                          fontSize: 28,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w900,
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
             ),
            )
        ],
      ),
    ),
    );
  }
}
