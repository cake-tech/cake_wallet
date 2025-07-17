import 'dart:ui';
import 'package:cake_wallet/entities/main_actions.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class NavigationDock extends StatelessWidget {
  const NavigationDock({
    required this.dashboardViewModel,
    required this.currentTheme,
  });

  final DashboardViewModel dashboardViewModel;
  final MaterialThemeBase currentTheme;

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
                colors: _getColors(context, !currentTheme.isDark),
              ),
            ),
            //color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getColors(context, !currentTheme.isDark),
                ),
              ),
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
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
                                      key: action.key,
                                      image: Image.asset(action.image,
                                          height: 24,
                                          width: 24,
                                          color: Theme.of(context).colorScheme.primary),
                                      title: action.name(context),
                                      onClick: (action.isEnabled?.call(dashboardViewModel) ?? true)
                                          ? () async =>
                                              await action.onTap(context, dashboardViewModel)
                                          : null,
                                      textColor: action.isEnabled?.call(dashboardViewModel) ?? true
                                          ? null
                                          : Theme.of(context).colorScheme.onSurface,
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

  List<Color> _getColors(BuildContext context, bool isBright) {
    return isBright
        ? <Color>[
            CustomThemeColors.backgroundGradientColorLight.withAlpha(5),
            CustomThemeColors.backgroundGradientColorLight.withAlpha(50),
            CustomThemeColors.backgroundGradientColorLight.withAlpha(125),
            CustomThemeColors.backgroundGradientColorLight.withAlpha(150),
            CustomThemeColors.backgroundGradientColorLight.withAlpha(200),
            CustomThemeColors.backgroundGradientColorLight,
            CustomThemeColors.backgroundGradientColorLight
          ]
        : <Color>[
            CustomThemeColors.backgroundGradientColorDark.withAlpha(5),
            CustomThemeColors.backgroundGradientColorDark.withAlpha(50),
            CustomThemeColors.backgroundGradientColorDark.withAlpha(125),
            CustomThemeColors.backgroundGradientColorDark.withAlpha(150),
            CustomThemeColors.backgroundGradientColorDark.withAlpha(200),
            CustomThemeColors.backgroundGradientColorDark,
            CustomThemeColors.backgroundGradientColorDark
          ];
  }
}
