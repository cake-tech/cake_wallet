import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

class NewMainActions {
  final Key key;
  final String Function(BuildContext context) name;
  final String image;
  final VoidCallback onTap;
  final bool Function(DashboardViewModel viewModel)? isEnabled;
  final bool Function(DashboardViewModel viewModel)? canShow;

  NewMainActions._({
    required this.key,
    required this.name,
    required this.image,
    required this.onTap,
    this.isEnabled,
    this.canShow,

  });

  static List<NewMainActions> all = [
    homeAction,
    walletsAction,
    contactsAction,
    appsAction,
    chartsAction,
  ];

  static NewMainActions homeAction = NewMainActions._(
    name: (context) => 'Home', //TODO S.of(context).home,
    image: 'assets/images/main_actions/home.svg',
    key: ValueKey('dashboard_page_home_action_button_key'),
    onTap: () {},
  );

  static NewMainActions walletsAction = NewMainActions._(
    name: (context) => S.of(context).wallets,
    image: 'assets/images/main_actions/wallets.svg',
    key: ValueKey('dashboard_page_wallets_action_button_key'),
    onTap: () {},
  );


  static NewMainActions contactsAction = NewMainActions._(
    name: (context) => 'Contacts', //TODO S.of(context).contacts,
    image: 'assets/images/main_actions/contacts.svg',
    key: ValueKey('dashboard_page_contacts_action_button_key'),
    onTap: () {},
  );

  static NewMainActions appsAction = NewMainActions._(
    name: (context) => 'Apps', //TODO S.of(context).apps,
    image: 'assets/images/main_actions/apps.svg',
    key: ValueKey('dashboard_page_apps_action_button_key'),
    onTap: () {},
  );

  static NewMainActions chartsAction = NewMainActions._(
    name: (context) => 'Charts', //TODO S.of(context).charts,
    image: 'assets/images/main_actions/charts.svg',
    key: ValueKey('dashboard_page_charts_action_button_key'),
    onTap: () {},
  );
}
