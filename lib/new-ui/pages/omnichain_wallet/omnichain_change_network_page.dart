import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class OmniChainChangeNetworkPage extends StatelessWidget {
  const OmniChainChangeNetworkPage({
    super.key,
    required this.omniChainWalletCreationService,
  });

  final OmniChainWalletCreationService omniChainWalletCreationService;

  @override
  Widget build(BuildContext context) {
    return ModalNavigator(
      parentContext: context,
      rootPage: OmniChainChangeNetworkMainPage(
        omniChainWalletCreationService: omniChainWalletCreationService,
      ),
    );
  }
}

class OmniChainChangeNetworkMainPage extends StatefulWidget {
  OmniChainChangeNetworkMainPage({
    super.key,
    required this.omniChainWalletCreationService,
  }) : currentNetwork = omniChainWalletCreationService.appStore.wallet?.type;

  final OmniChainWalletCreationService omniChainWalletCreationService;
  final WalletType? currentNetwork;

  @override
  State<OmniChainChangeNetworkMainPage> createState() => _OmniChainChangeNetworkMainPageState();
}

class _OmniChainChangeNetworkMainPageState extends State<OmniChainChangeNetworkMainPage> {
  final TextEditingController _searchController = TextEditingController();

  List<WalletInfo> wallets = [];
  List<WalletInfo> filteredWallets = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentGroupWallets();

    _searchController.addListener(() {
      setState(() {
        final query = _searchController.text.toLowerCase();

        filteredWallets = query.isEmpty
            ? wallets
            : wallets
                .where((walletInfo) =>
                    walletTypeToDisplayName(walletInfo.type).toLowerCase().contains(query))
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentGroupWallets() async {
    final result = await widget.omniChainWalletCreationService.getCurrentWalletGroupWallets();

    if (!mounted) return;

    setState(() {
      wallets = result;
      filteredWallets = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentNetwork = widget.currentNetwork;
    return Column(
      children: [
        ModalTopBar(
          title: 'Change Network',
          leadingIcon: Icon(Icons.arrow_back_ios_new_outlined),
          onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          onTrailingPressed: () {},
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 112),
                        child: NewListSections(
                          showHeader: true,
                          sections: {
                            'Current Network': [
                              if (currentNetwork != null)
                                ListItemCheckbox(
                                  keyValue: 'current_network_button_key',
                                  label: walletTypeToString(currentNetwork),
                                  iconPath: getCryptoCurrencyIconForWalletListItem(currentNetwork),
                                  value: true,
                                  onChanged: (_) {},
                                )
                              else
                                ListItemCheckbox(
                                  keyValue: 'current_network_button_key',
                                  label: 'No Network',
                                  value: true,
                                  onChanged: (_) {},
                                ),
                            ],
                            'Other Chains': [
                              ...filteredWallets.map(
                                    (info) => ListItemCheckbox(
                                  keyValue: 'other_networks_${info.type.name}_button_key',
                                  label: walletTypeToString(info.type),
                                  iconPath: getCryptoCurrencyIconForWalletListItem(info.type),
                                  value: false,
                                  onChanged: (_) {
                                    // TODO: load selected wallet from current group
                                  },
                                ),
                              ),
                            ],
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: FloatingBlurWrapper(
                              horizontalPadding: 0.0,
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 5,
                                    fit: FlexFit.tight,
                                    child: NewSearchBar(controller: _searchController),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    flex: 2,
                                    fit: FlexFit.tight,
                                    child: PrimaryButton(
                                      key: const ValueKey('new_wallet_continue_button_key'),
                                      borderRadius: BorderRadius.circular(999999),
                                      onPressed: () {
                                        //TODO: continue action
                                      },
                                      text: 'Manage',
                                      borderColor:
                                          Theme.of(context).colorScheme.surfaceContainerHighest,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh
                                          .withAlpha(128),
                                      textColor: Theme.of(context).colorScheme.primary,
                                      isDisabled: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
