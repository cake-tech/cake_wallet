import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/setting_action_button.dart';
import 'package:cake_wallet/src/widgets/setting_actions.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/router.dart' as Router;
import 'package:cake_wallet/themes/extensions/menu_theme.dart';

final _settingsNavigatorKey = GlobalKey<NavigatorState>();

class DesktopSettingsPage extends StatefulWidget {
  const DesktopSettingsPage({super.key});


  @override
  State<DesktopSettingsPage> createState() => _DesktopSettingsPageState();
}

class _DesktopSettingsPageState extends State<DesktopSettingsPage> {
  final int itemCount = SettingActions.desktopSettings.length;

  int? currentPage;

  void _onItemChange(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                S.current.settings,
                style: textXLarge(),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ListView.separated(
                      padding: EdgeInsets.only(top: 0),
                      itemBuilder: (_, index) {
                        final item = SettingActions.desktopSettings[index];
                        final isLastTile = index == itemCount - 1;
                        return SettingActionButton(
                          isLastTile: isLastTile,
                          selectionActive: currentPage != null,
                          isSelected: currentPage == index,
                          isArrowVisible: true,
                          onTap: () {
                            if (currentPage != index) {
                              final settingContext =
                                  _settingsNavigatorKey.currentState?.context ?? context;
                              item.onTap.call(settingContext);
                              _onItemChange(index);
                            }
                          },
                          image: item.image,
                          title: item.name.call(context),
                        );
                      },
                      separatorBuilder: (_, index) => Container(
                        height: 1,
                        color: Theme.of(context).extension<CakeMenuTheme>()!.dividerColor,
                      ),
                      itemCount: itemCount,
                    ),
                  ),
                  Flexible(
                    flex: 2,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 500),
                      child: Navigator(
                        key: _settingsNavigatorKey,
                        initialRoute: Routes.empty_no_route,
                        onGenerateRoute: (settings) => Router.createRoute(settings),
                        onGenerateInitialRoutes:
                            (NavigatorState navigator, String initialRouteName) {
                          return [
                            navigator
                                .widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!
                          ];
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
