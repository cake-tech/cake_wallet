import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/asset_details_modal.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';


import 'asset_tile.dart';

class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 64.0),
      child: Observer(
        builder: (context) {
          final hasMweb = dashboardViewModel.hasMweb && dashboardViewModel.mwebEnabled;
          return ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            itemCount: dashboardViewModel.balanceViewModel.formattedBalances.length-1 + (hasMweb ? 2 : 0),
            itemBuilder: (context, index) {
              return Observer(builder: (context){
                if (hasMweb) {
                  return AssetTile(
                    showSwap: dashboardViewModel.isEnabledSwapAction,
                    balance: dashboardViewModel.balanceViewModel.formattedBalances.first,
                    showSecondary: index > 0 ? true : false,
                    wallet: dashboardViewModel.wallet,
                    chainIconPath: index > 0 ? dashboardViewModel.wallet.currency.chainIconPath! : "",
                    trailingText: index > 0 ? "MWEB" : null,
                    modalMode: index > 0
                        ? AssetDetailsModalModes.ltcPrivate
                        : AssetDetailsModalModes.ltcTransparent,
                    title: index > 0 ? "Litecoin Private" : null,
                  );
                }

                final balance = dashboardViewModel.balanceViewModel.formattedBalances.elementAt(index+1);
                return AssetTile(
                  showSwap: dashboardViewModel.isEnabledSwapAction,
                  balance: balance,
                  wallet: dashboardViewModel.wallet,
                  chainIconPath: dashboardViewModel.wallet.currency.chainIconPath ?? "",
                );
              });

            },
          );
        }
      ),
    );
  }
}
