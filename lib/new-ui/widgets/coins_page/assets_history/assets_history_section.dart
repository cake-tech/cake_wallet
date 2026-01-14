import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'assets_section.dart';
import 'history_section.dart';

class AssetsHistorySection extends StatefulWidget {
  AssetsHistorySection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  State<AssetsHistorySection> createState() => _AssetsHistorySectionState();
}

class _AssetsHistorySectionState extends State<AssetsHistorySection> {
  late final List<Widget> tabs;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    tabs = [
      if(widget.dashboardViewModel.balanceViewModel.formattedBalances.length>1)
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
        if(tabs.length>1)
        AssetsTopBar(
          onTabChange: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          selectedTab: _selectedTab,
        ),
        tabs[_selectedTab],
      ],
    );
  }
}
