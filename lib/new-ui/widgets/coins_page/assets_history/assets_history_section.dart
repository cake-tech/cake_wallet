import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'assets_section.dart';
import 'history_section.dart';

class AssetsHistorySectionTab {
  final String title;
  final Widget content;

  AssetsHistorySectionTab(this.title, this.content);
}

class AssetsHistorySection extends StatefulWidget {
  AssetsHistorySection({super.key, required this.dashboardViewModel, required this.nftViewModel});

  final DashboardViewModel dashboardViewModel;
  final NFTViewModel nftViewModel;

  @override
  State<AssetsHistorySection> createState() => _AssetsHistorySectionState();
}

class _AssetsHistorySectionState extends State<AssetsHistorySection> {
  List<AssetsHistorySectionTab> tabs = [];
  int _selectedTab = 0;

  void reloadTabs() {
    final oldTabLength = tabs.length;
    tabs = [
      if (widget.dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled || (widget.dashboardViewModel.hasMweb && widget.dashboardViewModel.mwebEnabled))
        AssetsHistorySectionTab(
            S.current.assets,
            AssetsSection(
              dashboardViewModel: widget.dashboardViewModel,
            )),
      AssetsHistorySectionTab(
          S.current.history,
          HistorySection(
            dashboardViewModel: widget.dashboardViewModel,
          )),
      if (isNFTACtivatedChain(widget.dashboardViewModel.wallet.type,
          chainId: widget.dashboardViewModel.wallet.chainId))
        AssetsHistorySectionTab(S.current.nfts, NFTListingPage(nftViewModel: widget.nftViewModel))
    ];
    if (oldTabLength != tabs.length) {
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
          tabs: tabs.map((item) => item.title).toList(),
          onTabChange: (index) {
            setState(() {
                _selectedTab = index;
              });
            },
            selectedTab: _selectedTab,
          ),
        IndexedStack(
          index: _selectedTab,
          children: List.generate(tabs.length, (index) => tabs[index].content),
        )
      ],
    );
  }
}
