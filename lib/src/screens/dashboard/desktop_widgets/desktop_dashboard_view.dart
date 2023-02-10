import 'package:cake_wallet/routes.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/router.dart' as Router;

GlobalKey<NavigatorState> desktopKey = GlobalKey<NavigatorState>();

class DesktopDashboardView extends StatelessWidget {
  final Widget balancePage;

  const DesktopDashboardView(this.balancePage, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: balancePage,
        ),
        Expanded(
          flex: 5,
          child: Navigator(
            key: desktopKey,
            initialRoute: Routes.desktop_actions,
            onGenerateRoute: (settings) => Router.createRoute(settings),
            onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
              return [navigator.widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!];
            },
          ),
        ),
      ],
    );
  }
}
