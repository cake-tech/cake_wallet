import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:auto_size_text/auto_size_text.dart';

class BalancePage extends StatelessWidget{
  BalancePage({@required this.dashboardViewModel, @required this.settingsStore});

  final DashboardViewModel dashboardViewModel;
  final SettingsStore settingsStore;
  
  Color get backgroundLightColor =>
      settingsStore.currentTheme.type == ThemeType.bright ? Colors.transparent : Colors.white;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () =>
      dashboardViewModel.balanceViewModel.isReversing =
      !dashboardViewModel.balanceViewModel.isReversing,
      onLongPressUp: () =>
      dashboardViewModel.balanceViewModel.isReversing =
      !dashboardViewModel.balanceViewModel.isReversing,
      child: Column(
        children: [
          SizedBox(height: 56),
          Container(
            alignment: Alignment.topLeft,
            margin: const EdgeInsets.only(left: 24, bottom: 16),
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
  
             Container(     
               margin: const EdgeInsets.only(left: 16, right: 16),
               decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(color: settingsStore.currentTheme.type == ThemeType.bright ? Color.fromRGBO(255, 255, 255, 0.2): Colors.transparent, width: 1, ),
                  color:Theme.of(context).textTheme.title.backgroundColor
                ),
               child: Container(
                 margin: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
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
                  SizedBox(height: 8,),
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
                  SizedBox(height: 4,),
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
                  SizedBox(height: 26),
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
                  SizedBox(height: 8),
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
                  SizedBox(height: 4,),
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
                          fontWeight: FontWeight.w800,
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
            
        ],
      ),
  
    );
  }
}
