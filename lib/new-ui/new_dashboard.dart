import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/pages/home_page.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/cake_features_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/new_main_navbar_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:flutter/material.dart';
import 'package:progressive_blur/progressive_blur.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ProgressiveBlurWidget(
            sigma: 10.0,
            linearGradientBlur: const LinearGradientBlur(
              values: [0, 0.5, 1],
              stops: [0, 0.9, 1],
              start: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            child: widget.dashboardPageWidgets[_selectedPage],
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
    );
  }
}
