import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omnichain_wallet/omnichain_wallet_creation/omnichain_wallet_creation_state.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewOmnichainOpenNetworkPage extends BasePage {
  NewOmnichainOpenNetworkPage();

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) => const NewOmnichainOpenNetworkPageBody();
}

class NewOmnichainOpenNetworkPageBody extends StatefulWidget {
  const NewOmnichainOpenNetworkPageBody({super.key});

  @override
  State<NewOmnichainOpenNetworkPageBody> createState() => _NewOmnichainOpenNetworkPageBodyState();
}

class _NewOmnichainOpenNetworkPageBodyState extends State<NewOmnichainOpenNetworkPageBody> {
  final TextEditingController _searchController = TextEditingController();

  List<WalletType> filteredTypes = [];

  @override
  void initState() {
    super.initState();

    final selectedTypes = context.read<OmniChainWalletBloc>().state.selectedTypes.toList();

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
  Widget build(BuildContext context) {
    return BlocConsumer<OmniChainWalletBloc, OmniChainWalletState>(
      listener: (context, state) {},
      builder: (context, state) {
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
                    state.groupName.isEmpty ? 'Shopping Wallet' : state.groupName,
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
                            ...filteredTypes.map(
                              (type) => ListItemRegularRow(
                                keyValue: 'open_network_${type.name}_button_key',
                                label: walletTypeToDisplayName(type),
                                showArrow: false,
                                iconPath: getCryptoCurrencyIconForWalletListItem(type),
                                onTap: () {
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
                                const SizedBox(width: 12),
                                Flexible(
                                  flex: 2,
                                  fit: FlexFit.tight,
                                  child: PrimaryButton(
                                    key: const ValueKey('new_wallet_continue_button_key'),
                                    borderRadius: BorderRadius.circular(999999),
                                    onPressed: () {
                                      // TODO: manage networks action
                                    },
                                    text: 'Manage',
                                    borderColor:
                                        Theme.of(context).colorScheme.surfaceContainerHighest,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh
                                        .withAlpha(128),
                                    textColor: Theme.of(context).colorScheme.primary,
                                    isDisabled: !state.hasAnySelected,
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
      },
    );
  }
}
