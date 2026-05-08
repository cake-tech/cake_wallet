import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_managing/omnichain_wallet_managing_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_managing/omnichain_wallet_managing_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_managing/omnichain_wallet_managing_state.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_elevated_button.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
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
      rootPage: BlocProvider(
        create: (_) => OmniChainWalletManagingBloc(
          omniChainWalletCreationService: omniChainWalletCreationService,
        )..add(OmniChainWalletManagingLoaded()),
        child: OmniChainChangeNetworkMainPage(
          omniChainWalletCreationService: omniChainWalletCreationService,
        ),
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

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      context.read<OmniChainWalletManagingBloc>().add(
            OmniChainWalletManagingSearchChanged(_searchController.text),
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OmniChainWalletManagingBloc, OmniChainWalletManagingState>(
      builder: (context, state) {
        final currentNetwork = state.currentNetwork;

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
                                      iconPath:
                                          getCryptoCurrencyIconForWalletListItem(currentNetwork),
                                      value: state.selectedWallet == null,
                                      onChanged: (_) {},
                                    )
                                  else
                                    ListItemCheckbox(
                                      keyValue: 'current_network_button_key',
                                      label: 'No Network',
                                      value: state.selectedWallet == null,
                                      onChanged: (_) {},
                                    ),
                                ],
                                'Other Chains': [
                                  ...state.filteredWallets.map(
                                    (info) => ListItemCheckbox(
                                      keyValue: 'other_networks_${info.type.name}_button_key',
                                      label: walletTypeToString(info.type),
                                      iconPath: getCryptoCurrencyIconForWalletListItem(info.type),
                                      value: state.selectedWallet?.type == info.type,
                                      onChanged: (_) {
                                        context.read<OmniChainWalletManagingBloc>().add(
                                              OmniChainWalletManagingActivateSelectedWallet(info),
                                            );
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
                                        child: NewElevatedButton(
                                            key: const ValueKey(
                                                'change_network_wallet_manage_button_key'),
                                            buttonText: 'Manage',
                                            onPressed: () {
                                              // TODO: manage networks action
                                            }),
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
      },
    );
  }
}
