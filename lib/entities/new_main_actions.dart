import 'package:cake_wallet/generated/i18n.dart';
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
    image: 'assets/new-ui/Home.svg',
    key: ValueKey('dashboard_page_home_action_button_key'),
    onTap: () {},
  );

  static NewMainActions walletsAction = NewMainActions._(
    name: (context) => S.of(context).wallets,
    image: 'assets/new-ui/Wallets.svg',
    key: ValueKey('dashboard_page_wallets_action_button_key'),
    onTap: () {},
  );


  static NewMainActions contactsAction = NewMainActions._(
    name: (context) => 'Contacts', //TODO S.of(context).contacts,
    image: 'assets/new-ui/Contacts.svg',
    key: ValueKey('dashboard_page_contacts_action_button_key'),
    onTap: () {},
  );

  static NewMainActions appsAction = NewMainActions._(
    name: (context) => 'Apps', //TODO S.of(context).apps,
    image: 'assets/new-ui/Apps.svg',
    key: ValueKey('dashboard_page_apps_action_button_key'),
    onTap: () {},
  );

  static NewMainActions chartsAction = NewMainActions._(
    name: (context) => 'Charts', //TODO S.of(context).charts,
    image: 'assets/new-ui/Charts.svg',
    key: ValueKey('dashboard_page_charts_action_button_key'),
    onTap: () {},
  );
}
