import "package:cake_wallet/core/wallet_network.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/wallet_network_bloc.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/utils/responsive_layout_util.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

typedef OnWalletNetworkSelected = void Function(BuildContext, WalletNetwork);

class WalletNetworkPage extends StatelessWidget {
  const WalletNetworkPage({required this.bloc, required this.onSelected, super.key});

  final WalletNetworkBloc bloc;
  final OnWalletNetworkSelected onSelected;

  @override
  Widget build(BuildContext context) => BlocProvider<WalletNetworkBloc>(
        create: (_) => bloc,
        child: _WalletNetworkBody(onSelected: onSelected),
      );
}

class _WalletNetworkBody extends StatefulWidget {
  const _WalletNetworkBody({required this.onSelected});

  final OnWalletNetworkSelected onSelected;

  @override
  State<_WalletNetworkBody> createState() => _WalletNetworkBodyState();
}

class _WalletNetworkBodyState extends State<_WalletNetworkBody> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mode = context.read<WalletNetworkBloc>().mode;

    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.surface, colors.surfaceDim],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
              ),
              child: Column(
                children: [
                  ModalTopBar(
                    title: S.of(context).wallet_network,
                    leadingIcon: const Icon(Icons.arrow_back_ios_new),
                    leadingSemanticLabel: S.of(context).seed_alert_back,
                    onLeadingPressed: () => Navigator.of(context).maybePop(),
                    padding: const EdgeInsets.all(20),
                    titleStyle: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.08,
                    ),
                  ),
                  Expanded(
                    child: BlocBuilder<WalletNetworkBloc, WalletNetworkState>(
                      builder: (context, state) => SingleChildScrollView(
                        key: const ValueKey("wallet_network_scrollable_key"),
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: mode is WalletNetworkHardware
                                  ? const _HardwareWalletHeader()
                                  : const CakeImageWidget(
                                      imageUrl: "assets/new-ui/wallet.svg",
                                      width: 100,
                                      height: 100,
                                    ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 30),
                              child: Text(
                                S.of(context).wallet_network_description,
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: -0.06,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: CurrencyPickerSearchField(
                                key: const ValueKey("wallet_network_search_field_key"),
                                controller: _searchController,
                                hintText: S.of(context).search,
                                isCompact: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: _NetworkSections(
                                state: state,
                                onSelected: (network) => _onSelected(mode, network),
                                onManageBuiltinNetworks: _openManageBuiltinNetworks,
                                onAddNetworks: _openAddNetworks,
                                onManageAddedNetworks: _openManageEvmNetworks,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchChanged() =>
      context.read<WalletNetworkBloc>().add(WalletNetworkSearchChanged(_searchController.text));

  Future<void> _onSelected(WalletNetworkMode mode, WalletNetwork network) async {
    if (mode is WalletNetworkCreate && isBIP39Wallet(network.type)) {
      final hasWallets = (await WalletInfo.getAll()).isNotEmpty;
      if (!mounted) {
        return;
      }

      if (hasWallets) {
        await Navigator.of(context).pushNamed(Routes.walletGroupDescription, arguments: network);
        return;
      }
    }

    if (!mounted) {
      return;
    }

    widget.onSelected(context, network);
  }

  Future<void> _openManageBuiltinNetworks() async {
    await Navigator.of(context).pushNamed(Routes.manageBuiltinNetworks);
    _refresh();
  }

  Future<void> _openAddNetworks() async {
    final shouldContinue =
        await Navigator.of(context).pushNamed<bool>(Routes.addEvmNetworksDisclaimer);
    if (shouldContinue != true) {
      return;
    }

    await _openManageEvmNetworks();
  }

  Future<void> _openManageEvmNetworks() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushNamed(Routes.manageEvmNetworks);
    _refresh();
  }

  void _refresh() {
    if (mounted) {
      context.read<WalletNetworkBloc>().add(const WalletNetworkRefreshed());
    }
  }
}

class _NetworkSections extends StatelessWidget {
  const _NetworkSections({
    required this.state,
    required this.onSelected,
    required this.onManageBuiltinNetworks,
    required this.onAddNetworks,
    required this.onManageAddedNetworks,
  });

  final WalletNetworkState state;
  final ValueChanged<WalletNetwork> onSelected;
  final VoidCallback onManageBuiltinNetworks;
  final VoidCallback onAddNetworks;
  final VoidCallback onManageAddedNetworks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final builtinRows = state.visibleBuiltinRows;
    final addedRows = state.visibleAddedRows;
    final hasNoMatch = builtinRows.isEmpty && addedRows.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (builtinRows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              S.of(context).builtin_networks,
              style: textTheme.labelMedium?.copyWith(letterSpacing: -0.06),
            ),
          ),
          NewListSections(
            isDense: true,
            sections: {
              "": [
                ...builtinRows.map((row) => _listItemFor(context, row)),
                ListItemRegularRow(
                  keyValue: "wallet_network_manage_builtin_row_key",
                  label: S.of(context).manage_builtin_networks,
                  foregroundColor: colors.primary,
                  onTap: onManageBuiltinNetworks,
                ),
              ],
            },
          ),
          const SizedBox(height: 24),
        ],
        if (hasNoMatch) ...[
          Text(
            S.of(context).no_networks_found,
            key: const ValueKey("wallet_network_no_networks_found_text_key"),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
        ],
        if (evm != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              spacing: 4,
              children: [
                CakeImageWidget(
                  imageUrl: "assets/new-ui/plus.svg",
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(colors.onSurfaceVariant, BlendMode.srcIn),
                ),
                Text(
                  state.hasAddedNetworks
                      ? S.of(context).added_evm_networks
                      : S.of(context).more_networks,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: -0.06,
                  ),
                ),
              ],
            ),
          ),
          NewListSections(
            isDense: true,
            sections: {
              "": [
                ...addedRows.map((row) => _listItemFor(context, row)),
                if (state.hasAddedNetworks)
                  ListItemRegularRow(
                    keyValue: "wallet_network_manage_added_row_key",
                    label: S.of(context).manage_added_networks,
                    foregroundColor: colors.primary,
                    onTap: onManageAddedNetworks,
                  )
                else
                  ListItemRegularRow(
                    keyValue: "wallet_network_add_evm_networks_row_key",
                    label: S.of(context).add_evm_networks,
                    foregroundColor: colors.primary,
                    onTap: onAddNetworks,
                  ),
              ],
            },
          ),
        ],
      ],
    );
  }

  ListItem _listItemFor(BuildContext context, WalletNetworkRow row) {
    final network = row.network;
    final chainId = network.chainId;

    return ListItemRegularRow(
      keyValue: chainId == null
          ? "wallet_network_${network.type.name}_row_key"
          : "wallet_network_evm_${chainId}_row_key",
      label: row.name,
      subtitle: network.type == WalletType.bitcoin ? S.of(context).mainnet_and_lightning : null,
      iconPath: chainId == null ? row.iconPath : null,
      leadingWidget: chainId == null
          ? null
          : CakeImageWidget(
              imageUrl: row.iconPath,
              width: 24,
              height: 24,
              isRoundedSquare: true,
              isOutlined: row.isManual,
              fallbackName: row.name,
            ),
      onTap: () => onSelected(network),
    );
  }
}

class _HardwareWalletHeader extends StatelessWidget {
  const _HardwareWalletHeader();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 138,
        height: 75,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/hardware_wallet.svg",
                width: 75,
                height: 75,
              ),
            ),
            Positioned(
              left: 63,
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/cake_coin.svg",
                width: 75,
                height: 75,
              ),
            ),
          ],
        ),
      );
}
