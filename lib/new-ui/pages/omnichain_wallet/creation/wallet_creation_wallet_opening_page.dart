import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_state.dart";
import "package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/image_widgets/wallet_icon_widget.dart";
import "package:cake_wallet/new-ui/widgets/new_search_bar.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class WalletCreationOpeningPage extends BasePage {
  WalletCreationOpeningPage();

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => const WalletCreationOpeningPageBody();
}

class WalletCreationOpeningPageBody extends StatefulWidget {
  const WalletCreationOpeningPageBody({super.key});

  @override
  State<WalletCreationOpeningPageBody> createState() => _WalletCreationOpeningPageBodyState();
}

class _WalletCreationOpeningPageBodyState extends State<WalletCreationOpeningPageBody> {
  final TextEditingController _searchController = TextEditingController();

  List<WalletType> filteredTypes = [];

  @override
  void initState() {
    super.initState();

    final blocState = context.read<OmniChainWalletBloc>().state;
    final selectedTypes = switch (blocState) {
      WalletCreationOpeningNetwork(:final selectedTypes) => selectedTypes.toList(),
      _ => <WalletType>[],
    };

    filteredTypes = selectedTypes;

    _searchController.addListener(() {
      setState(() {
        final query = _searchController.text.toLowerCase();

        filteredTypes = selectedTypes
            .where((type) => walletTypeToDisplayName(type).toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<OmniChainWalletBloc, WalletCreationState>(

    builder: (context, state) {
      final isCreating = state is WalletCreationCreating;

      final (groupName, walletIcon) = switch (state) {
        WalletCreationOpeningNetwork(:final groupName, :final walletIcon) => (
        groupName,
        walletIcon,
        ),
        WalletCreationCreating(:final request) => (request.groupName, request.walletIcon),
        _ => ("", null),
      };

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                WalletIconAvatar(icon: walletIcon, size: 24, contentSize: 24),
                const SizedBox(width: 8),
                Text(
                  groupName,
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 112),
                    child: NewListSections(
                      sections: {
                        '': [
                          ...filteredTypes.map(
                                (type) => ListItemRegularRow(
                              keyValue: 'open_network_${type.name}_button_key',
                              label: walletTypeToDisplayName(type),
                              showArrow: false,
                              iconPath: getCryptoCurrencyIconForWalletListItem(type),
                              onTap: isCreating
                                  ? null
                                  : () {
                                final bloc = context.read<OmniChainWalletBloc>();
                                bloc.add(OmniChainWalletPrimaryTypeSelected(type));
                                bloc.add(OmniChainWalletGroupCreateRequested());
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
                              // const SizedBox(width: 12),
                              // Flexible(
                              //     flex: 2,
                              //     fit: FlexFit.tight,
                              //     child: NewElevatedButton(
                              //       key: const ValueKey('new_wallet_manage_button_key'),
                              //       onPressed: () {
                              //         // TODO: manage networks action
                              //       },
                              //       buttonText: 'Manage',
                              //     )),
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
    },
  );
}