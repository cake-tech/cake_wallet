import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'assets_section.dart';
import 'history_section.dart';

class LightningAssets extends StatefulWidget {
  LightningAssets({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  State<LightningAssets> createState() => _LightningAssetsState();
}

class _LightningAssetsState extends State<LightningAssets> {
  late final List<Widget> lightningTabs;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    lightningTabs = [
      AssetsSection(
        dashboardViewModel: widget.dashboardViewModel,
      ),
      HistorySection(
        dashboardViewModel: widget.dashboardViewModel,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AssetsTopBar(
          onTabChange: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          selectedTab: _selectedTab,
        ),
        lightningTabs[_selectedTab],
      ],
    );
  }
}
