import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_dashboard_page.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu_item.dart';
import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_wallet_selection_dropdown.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/sync_indicator.dart';
import 'package:cake_wallet/src/widgets/desktop_nav_bar.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/desktop_sidebar_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/router.dart' as Router;
import 'package:mobx/mobx.dart';

class DesktopSidebarWrapper extends BasePage {
  final Widget child;
  final DesktopSidebarViewModel desktopSidebarViewModel;
  final DashboardViewModel dashboardViewModel;

  DesktopSidebarWrapper({
    required this.child,
    required this.desktopSidebarViewModel,
    required this.dashboardViewModel,
  });

  static Key _pageViewKey = GlobalKey();

  @override
  PreferredSizeWidget desktopAppBar(BuildContext context) => DesktopNavbar(
        leading: Padding(
          padding: EdgeInsets.only(left: sideMenuWidth),
          child: getIt<DesktopWalletSelectionDropDown>(),
        ),
        middle: SyncIndicator(
          dashboardViewModel: dashboardViewModel,
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(Routes.connectionSync),
        ),
        trailing: InkWell(
          onTap: () {
            String? currentPath;

            DesktopDashboardPage.desktopKey.currentState?.popUntil((route) {
              currentPath = route.settings.name;
              return true;
            });

            switch (currentPath) {
              case Routes.transactionsPage:
                desktopSidebarViewModel.resetSidebar();
                break;
              default:
                desktopSidebarViewModel.resetSidebar();
                Future.delayed(Duration(milliseconds: 10), () {
                  desktopSidebarViewModel.onPageChange(SidebarItem.transactions);
                  DesktopDashboardPage.desktopKey.currentState?.pushNamed(Routes.transactionsPage);
                });
            }
          },
          child: Observer(
            builder: (_) {
              return Image.asset(
                desktopSidebarViewModel.currentPage == SidebarItem.transactions
                    ? selectedIconPath
                    : unselectedIconPath,
              );
            },
          ),
        ),
      );

  @override
  bool get resizeToAvoidBottomInset => false;

  final pageController = PageController();

  final selectedIconPath = 'assets/images/desktop_transactions_solid_icon.png';
  final unselectedIconPath = 'assets/images/desktop_transactions_outline_icon.png';

  double get sideMenuWidth => 76.0;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).accentColor,
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).primaryColor,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: scaffold,
          );

  @override
  Widget body(BuildContext context) {
    _setEffects();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Observer(builder: (_) {
          return SideMenu(
            width: sideMenuWidth,
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
            key: _pageViewKey,
            controller: pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              child,
              Container(
                padding: EdgeInsets.all(20),
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

  final desktopKey = DesktopDashboardPage.desktopKey;

  void _setEffects() async {
    reaction<SidebarItem>((_) => desktopSidebarViewModel.currentPage, (page) {
      String? currentPath;

      desktopKey.currentState?.popUntil((route) {
        currentPath = route.settings.name;
        return true;
      });
      if (page == SidebarItem.transactions) {
        return;
      }

      if (currentPath == Routes.transactionsPage) {
        Navigator.of(desktopKey.currentContext!).pop();
      }
      pageController.jumpToPage(page.index);
    });
  }
}
