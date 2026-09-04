import "package:another_flushbar/flushbar.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/modal_navigator.dart";
import "package:cake_wallet/new-ui/pages/omnichain_wallet/managing/omnichain_manage_networks.dart";
import "package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_state.dart";
import "package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/new_elevated_button.dart";
import "package:cake_wallet/new-ui/widgets/new_search_bar.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/show_bar.dart";
import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class OmniChainChangeNetworkPage extends StatelessWidget {
  const OmniChainChangeNetworkPage({
    required this.omniChainWalletCreationService,
    super.key,
  });

  final OmniChainWalletCreationService omniChainWalletCreationService;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => OmniChainWalletManagingBloc(
          omniChainWalletCreationService: omniChainWalletCreationService,
        )..add(OmniChainWalletManagingLoaded()),
        child: ModalNavigator(
          parentContext: context,
          rootPage: OmniChainChangeNetworkMainPage(
            omniChainWalletCreationService: omniChainWalletCreationService,
          ),
        ),
      );
}

class OmniChainChangeNetworkMainPage extends StatefulWidget {
  OmniChainChangeNetworkMainPage({
    required this.omniChainWalletCreationService,
    super.key,
  }) : currentNetwork = omniChainWalletCreationService.appStore.wallet?.type;

  final OmniChainWalletCreationService omniChainWalletCreationService;
  final WalletType? currentNetwork;

  @override
  State<OmniChainChangeNetworkMainPage> createState() => _OmniChainChangeNetworkMainPageState();
}

class _OmniChainChangeNetworkMainPageState extends State<OmniChainChangeNetworkMainPage> {
  final TextEditingController _searchController = TextEditingController();
  Flushbar<void>? _progressBar;

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
    _progressBar?.dismiss();
    _searchController.dispose();
    super.dispose();
  }

  void _changeProcessText(String text) {
    try {
      _progressBar?.dismiss();
      _progressBar = createBar<void>(text, context, duration: null)..show(context);
    } catch (_) {}
  }

  Future<void> _hideProgressText() async {
    final bar = _progressBar;
    if (bar == null) return;
    _progressBar = null;
    await Future.delayed(const Duration(milliseconds: 50), () {
      try {
        bar.dismiss();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<OmniChainWalletManagingBloc, OmniChainWalletManagingState>(
        listenWhen: (prev, curr) =>
            (prev.isLoading != curr.isLoading && curr.selectedWallet != null) ||
            (curr.error != null && curr.error != prev.error) ||
            (!prev.closeRequested && curr.closeRequested),
        listener: (context, state) {
          if (state.isLoading && state.selectedWallet != null) {
            _changeProcessText(
                'Loading ${walletTypeToString(state.selectedWallet!.type)} wallet...');
            return;
          }
          if (!state.isLoading && state.selectedWallet != null) {
            _hideProgressText();
          }
          if (state.closeRequested) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        builder: (context, state) {
          final current = widget.currentNetwork;
          final isEvm = current != null && isEVMCompatibleChain(current);

          final groupTypes = <WalletType>[
            if (current != null) current,
            ...state.wallets.map((w) => w.type),
          ];
          final evmTypes = groupTypes.where(isEVMCompatibleChain).toList();

          final currentSectionTitle = isEvm ? "Ethereum Ecosystem" : "Current Network";
          return Column(
            children: [
              ModalTopBar(
                title: "Change Network",
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
                onLeadingPressed: () => Navigator.of(context).maybePop(),
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
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 112),
                              child: NewListSections(
                                showHeader: true,
                                sections: {
                                  currentSectionTitle: isEvm
                                      ? [
                                          ...evmTypes.map(
                                            (type) => ListItemCheckbox(
                                              keyValue: "ecosystem_${type.name}_button_key",
                                              label: walletTypeToString(type),
                                              iconPath:
                                                  getCryptoCurrencyIconForWalletListItem(type),
                                              value: state.selectedWallet?.type == type ||
                                                  (state.selectedWallet == null && type == current),
                                              onChanged: (_) {
                                                if (state.isLoading) return;
                                                if (type == state.currentNetwork)
                                                  return; // already active
                                                final info =
                                                    state.wallets.firstWhere((w) => w.type == type);
                                                context.read<OmniChainWalletManagingBloc>().add(
                                                      OmniChainWalletManagingActivateSelectedWallet(
                                                          info),
                                                    );
                                              },
                                            ),
                                          ),
                                        ]
                                      : [
                                          if (current != null)
                                            ListItemCheckbox(
                                              keyValue: "current_network_button_key",
                                              label: walletTypeToString(current),
                                              iconPath:
                                                  getCryptoCurrencyIconForWalletListItem(current),
                                              value: state.selectedWallet == null,
                                              onChanged: (_) {},
                                            )
                                          else
                                            ListItemCheckbox(
                                              keyValue: "current_network_button_key",
                                              label: "No Network",
                                              value: state.selectedWallet == null,
                                              onChanged: (_) {},
                                            ),
                                        ],
                                  "Other Chains": [
                                    ...state.filteredWallets
                                        .where(
                                            (info) => !(isEvm && isEVMCompatibleChain(info.type)))
                                        .map(
                                          (info) => ListItemCheckbox(
                                            keyValue: "other_networks_${info.type.name}_button_key",
                                            label: walletTypeToString(info.type),
                                            iconPath:
                                                getCryptoCurrencyIconForWalletListItem(info.type),
                                            value: state.selectedWallet?.type == info.type,
                                            onChanged: (_) {
                                              if (state.isLoading) return;
                                              context.read<OmniChainWalletManagingBloc>().add(
                                                    OmniChainWalletManagingActivateSelectedWallet(
                                                        info),
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
                                                "change_network_wallet_manage_button_key",
                                              ),
                                              buttonText: 'Manage',
                                              onPressed: () async {
                                                final bloc =
                                                    context.read<OmniChainWalletManagingBloc>();
                                                final s = bloc.state;

                                                final existing = <WalletType>{
                                                  if (s.currentNetwork != null) s.currentNetwork!,
                                                  ...s.wallets.map((w) => w.type),
                                                };
                                                final available = availableWalletTypes
                                                    .where(isBIP39Wallet)
                                                    .toList();

                                                await Navigator.of(context).push<void>(
                                                  MaterialPageRoute<void>(
                                                    builder: (context) => Material(
                                                      color: Theme.of(context).colorScheme.surface,
                                                      child: OmniChainManageNetworksMainPage(
                                                        availableNetworks: available,
                                                        selectedNetworks: existing,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )),
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
