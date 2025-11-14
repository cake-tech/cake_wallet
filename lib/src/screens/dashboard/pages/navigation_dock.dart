import 'dart:ui';
import 'package:cake_wallet/entities/main_actions.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/action_button.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

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
            height: 84,
            alignment: Alignment.bottomCenter,
            decoration: dashboardViewModel.settingsStore.backgroundImage.isEmpty
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _getColors(context),
                    ),
                  )
                : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _getColors(context),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRect(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: MainActions.all
                            .where((element) =>
                                element.canShow?.call(dashboardViewModel) ??
                                true)
                            .map(
                              (action) => Expanded(
                                child: Semantics(
                                  button: true,
                                  enabled: (action.isEnabled
                                          ?.call(dashboardViewModel) ??
                                      true),
                                  child: ActionButton(
                                    key: action.key,
                                    image: Image.asset(
                                      action.image,
                                      height: 24,
                                      width: 24,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    title: action.name(context),
                                    onClick: (action.isEnabled
                                                ?.call(dashboardViewModel) ??
                                            true)
                                        ? () async => await action.onTap(
                                            context, dashboardViewModel)
                                        : null,
                                    textColor: action.isEnabled
                                                ?.call(dashboardViewModel) ??
                                            true
                                        ? null
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
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
          );
        },
      ),
    );
  }

  List<Color> _getColors(BuildContext context) {
    return <Color>[
      context.customColors.backgroundGradientColor.withAlpha(5),
      context.customColors.backgroundGradientColor.withAlpha(50),
      context.customColors.backgroundGradientColor.withAlpha(125),
      context.customColors.backgroundGradientColor.withAlpha(150),
      context.customColors.backgroundGradientColor.withAlpha(200),
      context.customColors.backgroundGradientColor,
      context.customColors.backgroundGradientColor,
    ];
  }
}
