import 'dart:io';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/new-ui/pages/home_page.dart';
import 'package:cake_wallet/new-ui/widgets/changelog_modal.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/cake_features_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/new_main_navbar_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/utils/version_comparator.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_model/dashboard/dashboard_view_model.dart';

class NewDashboard extends StatefulWidget {
  NewDashboard({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  final List<Widget> dashboardPageWidgets = [
    getIt.get<NewHomePage>(),
    getIt.get<WalletListPage>(),
    getIt.get<ContactListPage>(),
    getIt.get<CakeFeaturesPage>(),
    Placeholder(),
  ];

  @override
  State<NewDashboard> createState() => _NewDashboardState();
}

class _NewDashboardState extends State<NewDashboard> {
  int _selectedPage = 0;
  
  @override
  void initState() {
    super.initState();
    reaction((_)=>widget.dashboardViewModel.appStore.wallet, (_){setState(() {
      _selectedPage = 0;
    });});
    
    Future.delayed(Duration(milliseconds: 300)).then((_)=>_showChangelog(context));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      body: Material(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // widget.dashboardPageWidgets[_selectedPage],
            IndexedStack(
              index: _selectedPage,
              children: widget.dashboardPageWidgets,
            ),
            IgnorePointer(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(5),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(50),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(100),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(150),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(200),
                      Theme.of(context).colorScheme.surfaceDim.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: !(Platform.isIOS),
              child: SizedBox(
                width: double.infinity,
                height: NewMainNavBar.barHeight + NewMainNavBar.barBottomPadding,
                child: AbsorbPointer(
                  absorbing: true,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            NewMainNavBar(
              dashboardViewModel: widget.dashboardViewModel,
              selectedIndex: _selectedPage,
              onItemTap: (index) {
                setState(() {
                  _selectedPage = index;
                });
              },
            )
          ],
        ),
      ),
    );
  }

  void _showChangelog(BuildContext context) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final currentAppVersion = VersionComparator.getExtendedVersionNumber(
        widget.dashboardViewModel.settingsStore.appVersion);
    final lastSeenAppVersion = sharedPrefs.getInt(PreferencesKey.lastSeenAppVersion);
    final isNewInstall = sharedPrefs.getBool(PreferencesKey.isNewInstall);

    if (currentAppVersion != lastSeenAppVersion && !isNewInstall!) {
      Future<void>.delayed(
        Duration(seconds: 1),
        () {
          showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (context) {
                return ChangelogModal(
                  version: widget.dashboardViewModel.settingsStore.appVersion,
                );
              });
        },
      );

      sharedPrefs.setInt(PreferencesKey.lastSeenAppVersion, currentAppVersion);
    } else if (isNewInstall!) {
      sharedPrefs.setInt(PreferencesKey.lastSeenAppVersion, currentAppVersion);
    }
  }
}
