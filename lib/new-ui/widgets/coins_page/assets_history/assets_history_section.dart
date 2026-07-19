import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/assets_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_modal.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_top_bar.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/pages/nft_listing_page.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/nft_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'assets_section.dart';
import 'history_section.dart';

class AssetsHistorySectionActionButton {
  final String title;
  final String iconPath;
  final VoidCallback onPressed;

  const AssetsHistorySectionActionButton(this.title, this.iconPath, this.onPressed);
}

class AssetsHistorySectionTab {
  final String title;
  final Widget content;
  final AssetsHistorySectionActionButton? actionButton;

  const AssetsHistorySectionTab(this.title, this.content, this.actionButton);
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
    final hasAssetsTab = widget.dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled ||
        (widget.dashboardViewModel.hasMweb && widget.dashboardViewModel.mwebEnabled);
    final hasAssetsButton = widget.dashboardViewModel.balanceViewModel.isHomeScreenSettingsEnabled;
    final hasNftTab = isNFTACtivatedChain(widget.dashboardViewModel.wallet.type,
        chainId: widget.dashboardViewModel.wallet.chainId);
    tabs = [
      if (hasAssetsTab)
        AssetsHistorySectionTab(
            S.current.assets,
            AssetsSection(
              dashboardViewModel: widget.dashboardViewModel,
            ),
           hasAssetsButton ? AssetsHistorySectionActionButton(S.current.tokens, "assets/new-ui/options_slider.svg",

              () {Navigator.of(context).pushNamed(
                Routes.homeSettings,
                arguments: widget.dashboardViewModel.balanceViewModel,
              );
            }): null),
      AssetsHistorySectionTab(
          S.current.history,
          HistorySection(
            detailsAsPage: false,
            roundedTopSection: hasAssetsTab || hasNftTab,
            dashboardViewModel: widget.dashboardViewModel,
            short: true,
          ),
          AssetsHistorySectionActionButton(
              S.current.all_pascal_case, "assets/new-ui/arrow_right.svg", () {
            openHistoryModal(context);
          })),
      if (hasNftTab)
        AssetsHistorySectionTab(
            S.current.nfts, NFTListingPage(nftViewModel: widget.nftViewModel), null)
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

    reaction((_) => widget.dashboardViewModel.balanceViewModel.formattedBalances, (value) {
      reloadTabs();
    });
    reaction((_) => widget.dashboardViewModel.mwebEnabled, (_) => reloadTabs());
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        if (tabs.length > 1)
          AssetsTopBar(
            onTransactionHistoryOpened: () => openHistoryModal(context),
            dashboardViewModel: widget.dashboardViewModel,
            tabs: tabs,
            onTabChange: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
            selectedTab: _selectedTab,
          ),
        if (tabs.length == 1)
          Observer(
            builder: (_) => HistoryTopBar(
              onTap: () => openHistoryModal(context),
              roundedBottom: widget.dashboardViewModel.itemsShort.isEmpty,
            ),
          ),
        tabs[_selectedTab].content
      ],
    );
  }

  Future<void> openHistoryModal(BuildContext context) async {
    await CupertinoScaffold.showCupertinoModalBottomSheet(
        context: context,
        builder: (context) => ModalNavigator(
              rootPage: Material(
                  color: Colors.transparent,
                  child: HistoryModal(dashboardViewModel: widget.dashboardViewModel)),
              parentContext: context,
            ));
    widget.dashboardViewModel.changeAllFilterItems(true);
  }
}
