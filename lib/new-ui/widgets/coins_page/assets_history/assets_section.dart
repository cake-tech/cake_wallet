import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';

import '../../asset_tile.dart';

class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, index) {
        return AssetTile(
          iconPath: "assets/images/crypto/tether.webp",
          name: "DummyCoin",
          amount: "0.000 DMC",
          amountFiat: "\$ 0.00",
        );
      },
    );
  }
}
