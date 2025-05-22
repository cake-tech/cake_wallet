import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/balance/crypto_balance_widget.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/store/settings_store.dart';
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
        final isNFTActivated = isNFTACtivatedChain(dashboardViewModel.type);
        return DefaultTabController(
          key: ValueKey<bool>(isNFTActivated),
          length: isNFTActivated ? 2 : 1,
          child: Column(
            children: [
              if (isNFTActivated)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.label,
                      isScrollable: true,
                      physics: const NeverScrollableScrollPhysics(),
                      labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      unselectedLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      labelColor: Theme.of(context).colorScheme.primary,
                      dividerColor: Colors.transparent,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor:
                          Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                      tabAlignment: TabAlignment.start,
                      tabs: const [
                        Tab(text: 'My Crypto'),
                        Tab(text: 'My NFTs'),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    CryptoBalanceWidget(dashboardViewModel: dashboardViewModel),
                    if (isNFTActivated) NFTListingPage(nftViewModel: nftViewModel)
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
