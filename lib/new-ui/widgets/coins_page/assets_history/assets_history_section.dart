import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/material.dart';
import 'assets_section.dart';
import 'history_section.dart';

class AssetsHistorySection extends StatefulWidget {
  AssetsHistorySection({super.key, required this.dashboardViewModel, required this.nftViewModel});

  final DashboardViewModel dashboardViewModel;
  final NFTViewModel nftViewModel;

  @override
  State<AssetsHistorySection> createState() => _AssetsHistorySectionState();
}

class _AssetsHistorySectionState extends State<AssetsHistorySection> {
  late final List<Widget> tabs;
  late final List<String> tabNames;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    tabs = [
      HistorySection(
        dashboardViewModel: widget.dashboardViewModel,
      ),
      if(widget.dashboardViewModel.balanceViewModel.formattedBalances.length>1)
      AssetsSection(
        dashboardViewModel: widget.dashboardViewModel,
      ),
      if(isNFTACtivatedChain(widget.dashboardViewModel.wallet.type))
        NFTListingPage(nftViewModel: widget.nftViewModel)
    ];
    
    tabNames = [
        "History",
      if(widget.dashboardViewModel.balanceViewModel.formattedBalances.length>1)
        "Tokens",
      if(isNFTACtivatedChain(widget.dashboardViewModel.wallet.type))
        "NFTs"
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(tabs.length>1)
        AssetsTopBar(
          tabs: tabNames,
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
