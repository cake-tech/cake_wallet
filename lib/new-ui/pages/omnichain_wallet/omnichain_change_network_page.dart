import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_creation_service.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_state.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  const OmniChainChangeNetworkMainPage({
    super.key,
    required this.omniChainWalletCreationService,
  });

  final OmniChainWalletCreationService omniChainWalletCreationService;

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

    print('Loaded wallets for current group:::::: ${result.map((w) => w.name).join(', ')}');

    if (!mounted) return;

    setState(() {
      wallets = result;
      filteredWallets = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🛍️',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Text(
                'Shopping Wallet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Select a Network to Open',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 112),
                  child: NewListSections(
                    sections: {
                      '': [
                        ...filteredWallets.map(
                          (info) => ListItemRegularRow(
                            keyValue: 'open_network_${info.name}_button_key',
                            label: walletTypeToDisplayName(info.type),
                            showArrow: false,
                            iconPath: getCryptoCurrencyIconForWalletListItem(info.type),
                            onTap: () {
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
                                borderColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    );
  }
}
