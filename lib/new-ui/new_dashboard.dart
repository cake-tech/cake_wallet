import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/pages/home_page.dart';
import 'package:cake_wallet/new-ui/viewmodels/card_customizer/card_customizer_bloc.dart';
import 'package:cake_wallet/src/screens/contact/contact_list_page.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/cake_features_page.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/new_main_navbar_widget.dart';
import 'package:cake_wallet/src/screens/wallet_list/wallet_list_page.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  Widget build(BuildContext context) {
    return CupertinoScaffold(
      body: Material(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            MultiBlocProvider(providers: [
              BlocProvider<CardCustomizerBloc>(
                create: (_) => getIt.get<CardCustomizerBloc>(),
              )
            ], child: widget.dashboardPageWidgets[_selectedPage]),
            IgnorePointer(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      context.customColors.backgroundGradientColor.withAlpha(5),
                      context.customColors.backgroundGradientColor.withAlpha(50),
                      context.customColors.backgroundGradientColor.withAlpha(100),
                      context.customColors.backgroundGradientColor.withAlpha(150),
                      context.customColors.backgroundGradientColor.withAlpha(200),
                      context.customColors.backgroundGradientColor,
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
