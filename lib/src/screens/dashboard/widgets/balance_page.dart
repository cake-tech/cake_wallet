import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/exchange_trade/information_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/feature_flag.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/src/widgets/introducing_card.dart';
import 'package:cake_wallet/generated/i18n.dart';

class BalancePage extends StatelessWidget {
  BalancePage({required this.dashboardViewModel, required this.settingsStore});

  final DashboardViewModel dashboardViewModel;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => dashboardViewModel.balanceViewModel.isReversing =
          !dashboardViewModel.balanceViewModel.isReversing,
      onLongPressUp: () => dashboardViewModel.balanceViewModel.isReversing =
          !dashboardViewModel.balanceViewModel.isReversing,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 56),
            Container(
              margin: const EdgeInsets.only(left: 24, bottom: 16),
              child: Observer(
                builder: (_) {
                  return Row(
                    children: [
                      Text(
                        dashboardViewModel.balanceViewModel.asset,
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                          height: 1,
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                      if (dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled)
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, Routes.homeSettings,
                              arguments: dashboardViewModel.balanceViewModel),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/images/home_screen_settings_icon.png',
                              color:
                                  Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            Observer(
              builder: (_) {
                if (dashboardViewModel.balanceViewModel.isShowCard &&
                    FeatureFlag.isCakePayEnabled) {
                  return IntroducingCard(
                      title: S.of(context).introducing_cake_pay,
                      subTitle: S.of(context).cake_pay_learn_more,
                      borderColor: settingsStore.currentTheme.type == ThemeType.bright
                          ? Color.fromRGBO(255, 255, 255, 0.2)
                          : Colors.transparent,
                      closeCard: dashboardViewModel.balanceViewModel.disableIntroCakePayCard);
                }
                return Container();
              },
            ),
            Observer(
              builder: (_) {
                return ListView.separated(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => Container(padding: EdgeInsets.only(bottom: 8)),
                  itemCount: dashboardViewModel.balanceViewModel.formattedBalances.length,
                  itemBuilder: (__, index) {
                    final balance =
                        dashboardViewModel.balanceViewModel.formattedBalances.elementAt(index);
                    return buildBalanceRow(
                      context,
                      availableBalanceLabel:
                          '${dashboardViewModel.balanceViewModel.availableBalanceLabel}',
                      availableBalance: balance.availableBalance,
                      availableFiatBalance: balance.fiatAvailableBalance,
                      additionalBalanceLabel:
                          '${dashboardViewModel.balanceViewModel.additionalBalanceLabel}',
                      additionalBalance: balance.additionalBalance,
                      additionalFiatBalance: balance.fiatAdditionalBalance,
                      frozenBalance: balance.frozenBalance,
                      frozenFiatBalance: balance.fiatFrozenBalance,
                      currency: balance.formattedAssetTitle,
                      hasAdditionalBalance:
                          dashboardViewModel.balanceViewModel.hasAdditionalBalance,
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget buildBalanceRow(
    BuildContext context, {
    required String availableBalanceLabel,
    required String availableBalance,
    required String availableFiatBalance,
    required String additionalBalanceLabel,
    required String additionalBalance,
    required String additionalFiatBalance,
    required String frozenBalance,
    required String frozenFiatBalance,
    required String currency,
    required bool hasAdditionalBalance,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: settingsStore.currentTheme.type == ThemeType.bright
              ? Color.fromRGBO(255, 255, 255, 0.2)
              : Colors.transparent,
          width: 1,
        ),
        color: Theme.of(context).textTheme.titleLarge!.backgroundColor!,
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasAdditionalBalance ? () => _showBalanceDescription(context) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${availableBalanceLabel}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context)
                                      .accentTextTheme!
                                      .displaySmall!
                                      .backgroundColor!,
                                  height: 1)),
                          if (hasAdditionalBalance)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.help_outline,
                                  size: 16,
                                  color: Theme.of(context)
                                      .accentTextTheme!
                                      .displaySmall!
                                      .backgroundColor!),
                            ),
                        ],
                      ),
                      SizedBox(height: 6),
                      AutoSizeText(availableBalance,
                          style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context)
                                  .accentTextTheme!
                                  .displayMedium!
                                  .backgroundColor!,
                              height: 1),
                          maxLines: 1,
                          textAlign: TextAlign.start),
                      SizedBox(height: 6),
                      Text('${availableFiatBalance}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .accentTextTheme!
                                  .displayMedium!
                                  .backgroundColor!,
                              height: 1)),
                    ],
                  ),
                ),
                Text(currency,
                    style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).accentTextTheme!.displayMedium!.backgroundColor!,
                        height: 1)),
              ],
            ),
            if (frozenBalance.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 26),
                  Text(
                    S.current.frozen_balance,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentTextTheme.displaySmall!.backgroundColor!,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  AutoSizeText(
                    frozenBalance,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                      height: 1,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    frozenFiatBalance,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                      height: 1,
                    ),
                  ),
                ],
              ),
            if (hasAdditionalBalance)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  Text(
                    '${additionalBalanceLabel}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentTextTheme.displaySmall!.backgroundColor!,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 8),
                  AutoSizeText(
                    additionalBalance,
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                      height: 1,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${additionalFiatBalance}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).accentTextTheme.displayMedium!.backgroundColor!,
                      height: 1,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showBalanceDescription(BuildContext context) {
    showPopUp<void>(
        context: context,
        builder: (_) => InformationPage(information: S.current.available_balance_description));
  }
}
