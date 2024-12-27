import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/crypto_balance_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class BalancePage extends StatelessWidget {
  BalancePage({
    required this.dashboardViewModel,
    required this.settingsStore,
    required this.nftViewModel,
  });

  final DashboardViewModel dashboardViewModel;
  final NFTViewModel nftViewModel;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final isEVMCompatible = isEVMCompatibleChain(dashboardViewModel.type);
        return DefaultTabController(
          length: isEVMCompatible ? 2 : 1,
          child: Column(
            children: [
              if (isEVMCompatible)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      isScrollable: true,
                      physics: NeverScrollableScrollPhysics(),
                      labelStyle: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                        height: 1,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                        height: 1,
                      ),
                      labelColor:
                          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                      dividerColor: Colors.transparent,
                      indicatorColor:
                          Theme.of(context).extension<DashboardPageTheme>()!.pageTitleTextColor,
                      unselectedLabelColor: Theme.of(context)
                          .extension<DashboardPageTheme>()!
                          .pageTitleTextColor
                          .withOpacity(0.5),
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'My Crypto'),
                        Tab(text: 'My NFTs'),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    CryptoBalanceWidget(dashboardViewModel: dashboardViewModel),
                    if (isEVMCompatible) NFTListingPage(nftViewModel: nftViewModel)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
