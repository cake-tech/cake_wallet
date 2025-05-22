import 'dart:ui';
import 'package:cake_wallet/entities/main_actions.dart';
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
            height: 100,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _getColors(context),
              ),
            ),
            child: Container(
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
                                      key: ValueKey(
                                          'dashboard_page_${action.name(context)}_action_button_key'),
                                      image: Image.asset(
                                        action.image,
                                        height: 24,
                                        width: 24,
                                        color:  Theme.of(context).colorScheme.onSurface
                                      ),
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

  List<Color> _getColors(BuildContext context) {
    final isBright = !dashboardViewModel.appStore.themeStore.currentTheme.isDark;
    return isBright
        ? <Color>[
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(10),
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(75),
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(150),
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface
          ]
        : <Color>[
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(5),
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(50),
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(125),
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(150),
            Theme.of(context).colorScheme.surfaceContainer.withAlpha(200),
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface  
          ];
  }
}
