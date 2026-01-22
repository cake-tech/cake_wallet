import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';


import 'asset_tile.dart';

class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 64.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: dashboardViewModel.balanceViewModel.formattedBalances.length-1,
        itemBuilder: (context, index) {
          final balance = dashboardViewModel.balanceViewModel.formattedBalances.elementAt(index+1);
          return AssetTile(balance: balance);
        },
      ),
    );
  }
}
