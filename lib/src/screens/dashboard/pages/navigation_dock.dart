import 'dart:ui';
import 'package:cake_wallet/entities/main_actions.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/balance_page_theme.dart';
import '../../../../themes/theme_base.dart';

class NavigationDock extends StatelessWidget {
  const NavigationDock({
    required this.dashboardViewModel,
  });

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: Observer(
        builder: (_) {
          return Container(
            height: 150,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getColors(context),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(
                        color: Theme.of(context).extension<BalancePageTheme>()!.cardBorderColor,
                        width: 1,
                      ),
                      color:
                          Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: MainActions.all
                              .where((element) => element.canShow?.call(dashboardViewModel) ?? true)
                              .map(
                                (action) => Expanded(
                                  child: Semantics(
                                    button: true,
                                    enabled: (action.isEnabled?.call(dashboardViewModel) ?? true),
                                    child: ActionButton(
                                      key: ValueKey(
                                          'dashboard_page_${action.name(context)}_action_button_key'),
                                      image: Image.asset(
                                        action.image,
                                        height: 24,
                                        width: 24,
                                        color: action.isEnabled?.call(dashboardViewModel) ?? true
                                            ? Theme.of(context)
                                                .extension<DashboardPageTheme>()!
                                                .mainActionsIconColor
                                            : Theme.of(context)
                                                .extension<BalancePageTheme>()!
                                                .labelTextColor,
                                      ),
                                      title: action.name(context),
                                      onClick: () async =>
                                          await action.onTap(context, dashboardViewModel),
                                      textColor: action.isEnabled?.call(dashboardViewModel) ?? true
                                          ? null
                                          : Theme.of(context)
                                              .extension<BalancePageTheme>()!
                                              .labelTextColor,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Color> _getColors(BuildContext context) {
    final isBright = dashboardViewModel.settingsStore.currentTheme.type == ThemeType.bright;
    return isBright
        ? <Color>[
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(10),
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(75),
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(150),
            Theme.of(context).extension<DashboardPageTheme>()!.thirdGradientBackgroundColor,
            Theme.of(context).extension<DashboardPageTheme>()!.thirdGradientBackgroundColor
          ]
        : <Color>[
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(5),
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(50),
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(125),
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(150),
            Theme.of(context)
                .extension<DashboardPageTheme>()!
                .thirdGradientBackgroundColor
                .withAlpha(200),
            Theme.of(context).extension<DashboardPageTheme>()!.thirdGradientBackgroundColor,
            Theme.of(context).extension<DashboardPageTheme>()!.thirdGradientBackgroundColor
          ];
  }
}
