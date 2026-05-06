import 'dart:io';

import 'package:cake_wallet/core/new_wallet_type_arguments.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_bloc.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_event.dart';
import 'package:cake_wallet/new-ui/viewmodels/omni_chain_wallet/omni_chain_wallet_state.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/hardware/device_connection_type.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_creation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewChainSelectionPage extends BasePage {
  NewChainSelectionPage({
    required this.newWalletTypeArguments,
  });

  final NewWalletTypeArguments newWalletTypeArguments;

  @override
  String get title => S.current.new_wallet;

  @override
  Widget body(BuildContext context) {
    final flowWalletTypes = availableWalletTypes
        .where((element) =>
            newWalletTypeArguments.hardwareWalletType == null ||
            DeviceConnectionType.supportedConnectionTypes(
              element,
              newWalletTypeArguments.hardwareWalletType!,
              Platform.isIOS,
            ).isNotEmpty)
        .toList();

    return BlocProvider(
      create: (_) => OmniChainWalletBloc(
        allWalletTypes: flowWalletTypes.toSet(),
        creationService: getIt.get<OmniChainWalletCreationService>(),
      ),
      child: NewChainSelectionPageBody(
        isCreate: newWalletTypeArguments.isCreate,
        hardwareWalletType: newWalletTypeArguments.hardwareWalletType,
        availableWalletTypes: flowWalletTypes,
      ),
    );
  }
}

class NewChainSelectionPageBody extends StatefulWidget {
  NewChainSelectionPageBody({
    required this.isCreate,
    required this.availableWalletTypes,
    this.onTypeSelected,
    this.hardwareWalletType,
  });

  final bool isCreate;
  final List<WalletType> availableWalletTypes;
  final void Function(BuildContext, WalletType)? onTypeSelected;
  final HardwareWalletType? hardwareWalletType;

  bool get isHardwareWallet => hardwareWalletType != null;

  @override
  State<NewChainSelectionPageBody> createState() => _NewChainSelectionPageBodyState();
}

class _NewChainSelectionPageBodyState extends State<NewChainSelectionPageBody> {
  _NewChainSelectionPageBodyState() : types = const [];

  final TextEditingController _searchController = TextEditingController();

  List<WalletType> types;
  List<WalletType> filteredTypes = [];

  @override
  void initState() {
    super.initState();

    types = widget.availableWalletTypes;

    filteredTypes = context.read<OmniChainWalletBloc>().popularWalletTypes(types);

    _searchController.addListener(() {
      setState(() {
        final query = _searchController.text.toLowerCase();

        filteredTypes = query.isEmpty
            ? context.read<OmniChainWalletBloc>().popularWalletTypes(types)
            : types
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
    return BlocBuilder<OmniChainWalletBloc, OmniChainWalletState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24),
              CakeImageWidget(
                imageUrl: 'assets/new-ui/wallet_add_dark.svg',
                height: 100,
                width: 90,
              ),
              SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'Select networks to enable on your new wallet.You will still be able to change them later',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              SizedBox(height: 24),
              NewListSections(
                sections: {
                  '': [
                    ListItemRegularRow(
                      keyValue: 'all_chains',
                      label: 'All chains',
                      trailingText: '${types.length} items',
                      iconPath: 'assets/new-ui/chains.svg',
                      trailingTextPadding: const EdgeInsets.only(right: 24.0),
                      mainPadding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ]
                },
              ),
              SizedBox(height: 46),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Custom Selection",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 20,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            context.read<OmniChainWalletBloc>().add(OmniChainWalletTypesSelected()),
                        child: Text(
                          S.of(context).select_all,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context
                            .read<OmniChainWalletBloc>()
                            .add(OmniChainWalletTypesDeselected()),
                        child: Text(
                          S.of(context).unselect_all,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      )
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 112),
                      child: NewListSections(
                        showHeader: true,
                        sections: {
                          'Popular': [
                            ...filteredTypes.map(
                              (type) => ListItemCheckbox(
                                keyValue: 'new_wallet_${type.name}_button_key',
                                iconPath: getCryptoCurrencyIconForWalletListItem(type),
                                label: walletTypeToDisplayName(type),
                                value: state.isSelected(type),
                                onChanged: (bool value) => context.read<OmniChainWalletBloc>().add(
                                      OmniChainWalletTypeToggled(
                                        type: type,
                                        isSelected: value,
                                      ),
                                    ),
                              ),
                            ),
                          ]
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
                                      Navigator.of(context).pushNamed(
                                        Routes.newChainCustomizationPage,
                                        arguments: context.read<OmniChainWalletBloc>(),
                                      );
                                    },
                                    text: S.of(context).continue_text,
                                    color: Theme.of(context).colorScheme.primary,
                                    textColor: Theme.of(context).colorScheme.onPrimary,
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
