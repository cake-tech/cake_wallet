import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
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
  List<Widget> tabs = [];
  List<String> tabNames = [];
  int _selectedTab = 0;

  void reloadTabs() {
    final oldTabLength = tabs.length;
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
    if(oldTabLength!=tabs.length) {
      setState(() {
        _selectedTab = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    reloadTabs();

    reaction((_)=>widget.dashboardViewModel.balanceViewModel.formattedBalances, (value) {
      reloadTabs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if(tabs.length>1)
        AssetsTopBar(
          dashboardViewModel: widget.dashboardViewModel,
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
