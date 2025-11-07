import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class PageIndicatorActions {
  final String Function(BuildContext context) name;
  final String image;
  final Key key;
  final bool Function(DashboardViewModel viewModel)? isEnabled;
  final bool Function(DashboardViewModel viewModel)? canShow;

  PageIndicatorActions._({
    required this.name,
    required this.image,
    required this.key,
    this.isEnabled,
    this.canShow,
  });

  static List<PageIndicatorActions> all = [
    appsAction,
    homeAction,
    historyAction,
  ];

  static PageIndicatorActions appsAction = PageIndicatorActions._(
    name: (context) => S.of(context).apps,
    image: 'assets/images/main_actions/apps.svg',
    key: ValueKey('dashboard_page_apps_action_button_key'),
  );

  static PageIndicatorActions homeAction = PageIndicatorActions._(
    name: (context) => S.of(context).home,
    image: 'assets/images/main_actions/home.svg',
    key: ValueKey('dashboard_page_home_action_button_key'),
  );

  static PageIndicatorActions historyAction = PageIndicatorActions._(
    name: (context) => S.of(context).history,
    image: 'assets/images/main_actions/history.svg',
    key: ValueKey('dashboard_page_history_action_button_key'),
    isEnabled: (viewModel) => viewModel.isEnabledSwapAction,
    canShow: (viewModel) => viewModel.hasSwapAction,
  );
}
