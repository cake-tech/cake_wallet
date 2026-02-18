import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/pages/home_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/cake_features_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/new_main_navbar_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
}
