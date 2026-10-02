import "dart:async";

import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/wallet_network/network_page_scaffold.dart";
import "package:cake_wallet/new-ui/viewmodels/wallet_network/manage_evm_networks_bloc.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_search_field.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/list_item_regular_row_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/standard_switch.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cw_core/evm_network.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:intl/intl.dart";
import "package:url_launcher/url_launcher.dart";

class ManageEvmNetworksPage extends StatelessWidget {
  const ManageEvmNetworksPage({required this.bloc, super.key});

  final ManageEvmNetworksBloc bloc;

  @override
  Widget build(BuildContext context) => BlocProvider<ManageEvmNetworksBloc>(
        create: (_) => bloc,
        child: const _ManageEvmNetworksBody(),
      );
}

class _ManageEvmNetworksBody extends StatefulWidget {
  const _ManageEvmNetworksBody();

  @override
  State<_ManageEvmNetworksBody> createState() => _ManageEvmNetworksBodyState();
}

class _ManageEvmNetworksBodyState extends State<_ManageEvmNetworksBody> {
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

    return NetworkPageScaffold(
      title: S.of(context).manage_evm_networks,
      body: BlocPresentationListener<ManageEvmNetworksBloc, ManageEvmNetworksPresentation>(
        listener: _onPresentation,
        child: BlocBuilder<ManageEvmNetworksBloc, ManageEvmNetworksState>(
          builder: (context, state) => _NetworkList(
            state: state,
            searchController: _searchController,
            onEdit: _openDetails,
            onToggle: (network, {required shouldEnable}) => context
                .read<ManageEvmNetworksBloc>()
                .add(NetworkToggleRequested(network, shouldEnable: shouldEnable)),
          ),
        ),
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: NewPrimaryButton(
          key: const ValueKey("manage_evm_networks_add_manually_button_key"),
          onPressed: () => _openDetails(null),
          text: S.of(context).add_manually,
          color: colors.surfaceContainer,
          textColor: colors.primary,
          labelStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.07,
          ),
        ),
      ),
    );
  }

  void _onSearchChanged() => context
      .read<ManageEvmNetworksBloc>()
      .add(ManageEvmNetworksSearchChanged(_searchController.text));

  Future<void> _openDetails(EvmNetwork? network) async {
    await Navigator.of(context).pushNamed(Routes.evmNetworkDetails, arguments: network);

    if (mounted) {
      context.read<ManageEvmNetworksBloc>().add(const NetworksChanged());
    }
  }

  void _onPresentation(BuildContext context, ManageEvmNetworksPresentation event) {
    switch (event) {
      case BorrowedTickerConfirmationRequested():
        unawaited(_confirmBorrowedTicker(event.network));
      case RpcChainIdMismatchRefused():
        _showRefusal(
          S.of(context).rpc_chain_id_mismatch(
                event.networkName,
                event.answeredChainId.toString(),
                event.expectedChainId.toString(),
              ),
        );
      case RpcNoAnswerRefused():
        _showRefusal(S.of(context).rpc_no_answer(event.networkName));
      case NetworkInUseRefused():
        _showRefusal(
          S.of(context).network_used_cannot_disable(
                event.networkName,
                event.walletCount.toString(),
              ),
        );
      case NetworkToggleFailed():
        _showRefusal(event.message);
    }
  }

  Future<void> _confirmBorrowedTicker(EvmNetwork network) async {
    final isConfirmed = await showPopUp<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;

        return AlertWithTwoActions(
          alertTitle: S.of(dialogContext).warning,
          alertContent: S
              .of(dialogContext)
              .added_network_borrowed_ticker_warning(network.name, network.symbol),
          leftButtonText: S.of(dialogContext).cancel,
          rightButtonText: S.of(dialogContext).continue_text,
          alertLeftActionButtonKey:
              const ValueKey("manage_evm_networks_borrowed_ticker_cancel_button_key"),
          alertRightActionButtonKey:
              const ValueKey("manage_evm_networks_borrowed_ticker_continue_button_key"),
          leftAlertButtonStyle: AlertButtonStyle(
            backgroundColor: colors.primary,
            textColor: colors.onPrimary,
            fontWeight: FontWeight.w500,
          ),
          rightAlertButtonStyle: AlertButtonStyle.secondary(dialogContext),
          actionLeftButton: () => Navigator.of(dialogContext).pop(false),
          actionRightButton: () => Navigator.of(dialogContext).pop(true),
        );
      },
    );

    if (!mounted) {
      return;
    }

    // Dismissing the popup any other way counts as Cancel
    context
        .read<ManageEvmNetworksBloc>()
        .add(BorrowedTickerConfirmationAnswered(network, isConfirmed: isConfirmed == true));
  }

  void _showRefusal(String message) {
    unawaited(
      showPopUp<void>(
        context: context,
        builder: (dialogContext) => AlertWithOneAction(
          alertTitle: S.of(dialogContext).warning,
          alertContent: message,
          buttonText: S.of(dialogContext).ok,
          buttonKey: const ValueKey("manage_evm_networks_refusal_ok_button_key"),
          buttonAction: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.state});

  final ManageEvmNetworksState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final noteStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
          letterSpacing: -0.06,
        );
    final linkStyle = noteStyle?.copyWith(color: colors.primary);
    const source = "ChainList";
    final parts = S.of(context).network_data_fetched_from_chainlist.split(source);
    final chainListStatus = state.chainListStatus;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        spacing: 12,
        children: [
          const SizedBox.square(
            dimension: 75,
            child: Center(
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/evm_network.svg",
                width: 75,
                height: 62.3375,
              ),
            ),
          ),
          Semantics(
            link: true,
            child: GestureDetector(
              onTap: _openChainList,
              child: Text.rich(
                TextSpan(
                  style: noteStyle,
                  children: [
                    TextSpan(text: parts.first),
                    for (final part in parts.skip(1)) ...[
                      TextSpan(text: source, style: linkStyle),
                      TextSpan(text: part),
                    ],
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (chainListStatus is ChainListSavedCopy)
            Text(
              S.of(context).chainlist_update_failed_saved_copy(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toString(),
                    ).format(chainListStatus.date),
                  ),
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  void _openChainList() =>
      unawaited(launchUrl(Uri.https("chainlist.org"), mode: LaunchMode.externalApplication));
}

class _NetworkList extends StatelessWidget {
  const _NetworkList({
    required this.state,
    required this.searchController,
    required this.onEdit,
    required this.onToggle,
  });

  final ManageEvmNetworksState state;
  final TextEditingController searchController;
  final ValueChanged<EvmNetwork> onEdit;
  final void Function(EvmNetwork network, {required bool shouldEnable}) onToggle;

  @override
  Widget build(BuildContext context) {
    final visibleAlphabeticalNetworks = state.matchingSearch(state.alphabeticalNetworks);

    return CustomScrollView(
      key: const ValueKey("manage_evm_networks_scrollable_key"),
      slivers: [
        SliverToBoxAdapter(
          child: _ListHeader(
            state: state,
            searchController: searchController,
            manualRows: state
                .matchingSearch(state.manualNetworks)
                .map((network) => _networkRow(context, network))
                .toList(),
            popularRows: state
                .matchingSearch(state.popularNetworks)
                .map((network) => _networkRow(context, network))
                .toList(),
            hasAlphabeticalRows: visibleAlphabeticalNetworks.isNotEmpty,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverList.builder(
            itemCount: visibleAlphabeticalNetworks.length,
            itemBuilder: (context, index) {
              final network = visibleAlphabeticalNetworks[index];
              final row = _networkRow(context, network);

              return ListItemRegularRowWidget(
                key: ValueKey(row.keyValue),
                keyValue: row.keyValue,
                label: row.label,
                leadingWidget: row.leadingWidget,
                showArrow: false,
                trailingWidget: row.trailingWidget,
                isDense: true,
                isFirstInSection: index == 0,
                isLastInSection: index == visibleAlphabeticalNetworks.length - 1,
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: _ListFooter(state: state)),
      ],
    );
  }

  ListItemRegularRow _networkRow(BuildContext context, EvmNetwork network) {
    final isToggling = state.togglingChainIds.contains(network.chainId);

    return ListItemRegularRow(
      keyValue: "manage_evm_networks_${network.chainId}_row_key",
      label: network.name,
      leadingWidget: CakeImageWidget(
        imageUrl: network.iconUrl,
        width: 24,
        height: 24,
        isRoundedSquare: true,
        isOutlined: true,
        fallbackName: network.name,
      ),
      showArrow: false,
      trailingWidget: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditButton(
            key: ValueKey("manage_evm_networks_${network.chainId}_edit_button_key"),
            networkName: network.name,
            onPressed: isToggling ? null : () => onEdit(network),
          ),
          _EnableToggle(
            key: ValueKey("manage_evm_networks_${network.chainId}_toggle_key"),
            network: network,
            isToggling: isToggling,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.state,
    required this.searchController,
    required this.manualRows,
    required this.popularRows,
    required this.hasAlphabeticalRows,
  });

  final ManageEvmNetworksState state;
  final TextEditingController searchController;
  final List<ListItemRegularRow> manualRows;
  final List<ListItemRegularRow> popularRows;
  final bool hasAlphabeticalRows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SourceNote(state: state),
        const SizedBox(height: 16),
        CurrencyPickerSearchField(
          key: const ValueKey("manage_evm_networks_search_field_key"),
          controller: searchController,
          hintText: S.of(context).search,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              if (state.hasNoMatch)
                Text(
                  S.of(context).no_networks_found,
                  key: const ValueKey("manage_evm_networks_no_networks_found_text_key"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              if (manualRows.isNotEmpty)
                _Section(title: S.of(context).manually_added, rows: manualRows),
              if (popularRows.isNotEmpty)
                _Section(title: S.of(context).picker_section_popular, rows: popularRows),
              if (hasAlphabeticalRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SectionHeader(title: S.of(context).a_to_z),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<ListItemRegularRow> rows;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _SectionHeader(title: title),
          NewListSections(isDense: true, sections: {title: rows}),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: -0.06,
              ),
        ),
      );
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.state});

  final ManageEvmNetworksState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.chainListStatus is ChainListFetching && state.alphabeticalNetworks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (state.chainListStatus is ChainListFetchFailed) ...[
            const SizedBox(height: 24),
            Text(
              S.of(context).chainlist_fetch_failed,
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            NewPrimaryButton(
              key: const ValueKey("manage_evm_networks_try_again_button_key"),
              onPressed: () =>
                  context.read<ManageEvmNetworksBloc>().add(const ChainListRetryRequested()),
              text: S.of(context).try_again,
              color: colors.surfaceContainer,
              textColor: colors.primary,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.07,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.networkName, required this.onPressed, super.key});

  final String networkName;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: "${S.of(context).edit} $networkName",
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.only(left: 12, right: 8),
          alignment: Alignment.center,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: colors.surfaceContainerHigh, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: CakeImageWidget(
              imageUrl: "assets/new-ui/pencil.svg",
              width: 17.6,
              height: 17.6,
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _EnableToggle extends StatelessWidget {
  const _EnableToggle({
    required this.network,
    required this.isToggling,
    required this.onToggle,
    super.key,
  });

  final EvmNetwork network;
  final bool isToggling;
  final void Function(EvmNetwork network, {required bool shouldEnable}) onToggle;

  @override
  Widget build(BuildContext context) {
    if (isToggling) {
      return const SizedBox(
        width: 40,
        height: 24,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Semantics(
      label: network.name,
      child: StandardSwitch(
        isCompact: true,
        value: network.isEnabled,
        onTapped: () => onToggle(network, shouldEnable: !network.isEnabled),
      ),
    );
  }
}
