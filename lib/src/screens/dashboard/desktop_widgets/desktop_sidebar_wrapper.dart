import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_dashboard_page.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu_item.dart';
import 'package:cake_wallet/view_model/dashboard/desktop_sidebar_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/router.dart' as Router;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class DesktopSidebarWrapper extends StatelessWidget {
  final Widget child;
  final DesktopSidebarViewModel desktopSidebarViewModel;

  const DesktopSidebarWrapper({required this.child, required this.desktopSidebarViewModel});

  @override
  Widget build(BuildContext context) {
    final pageController = PageController();

    reaction<SidebarItem>((_) => desktopSidebarViewModel.currentPage, (page) {
      String? currentPath;

      DesktopDashboardPage.desktopKey.currentState?.popUntil((route) {
        currentPath = route.settings.name;
        return true;
      });
      if (page == SidebarItem.transactions) {
        return;
      }

      if (currentPath == Routes.transactionsPage) {
        Navigator.of(DesktopDashboardPage.desktopKey.currentContext!).pop();
      }

      pageController.jumpToPage(page.index);
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Observer(builder: (_) {
          return SideMenu(
            topItems: [
              SideMenuItem(
                iconPath: 'assets/images/wallet_outline.png',
                isSelected: desktopSidebarViewModel.currentPage == SidebarItem.dashboard,
                onTap: () => desktopSidebarViewModel.onPageChange(SidebarItem.dashboard),
              ),
            ],
            bottomItems: [
              SideMenuItem(
                  iconPath: 'assets/images/support_icon.png',
                  isSelected: desktopSidebarViewModel.currentPage == SidebarItem.support,
                  onTap: () => desktopSidebarViewModel.onPageChange(SidebarItem.support)),
              SideMenuItem(
                iconPath: 'assets/images/settings_outline.png',
                isSelected: desktopSidebarViewModel.currentPage == SidebarItem.settings,
                onTap: () => desktopSidebarViewModel.onPageChange(SidebarItem.settings),
              ),
            ],
          );
        }),
        Expanded(
          child: PageView(
            controller: pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              child,
              Container(
                child: Navigator(
                  initialRoute: Routes.support,
                  onGenerateRoute: (settings) => Router.createRoute(settings),
                  onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
                    return [
                      navigator.widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!
                    ];
                  },
                ),
              ),
              Navigator(
                initialRoute: Routes.desktop_settings_page,
                onGenerateRoute: (settings) => Router.createRoute(settings),
                onGenerateInitialRoutes: (NavigatorState navigator, String initialRouteName) {
                  return [
                    navigator.widget.onGenerateRoute!(RouteSettings(name: initialRouteName))!
                  ];
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
