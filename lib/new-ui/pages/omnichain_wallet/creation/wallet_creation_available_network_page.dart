import "dart:io";

import "package:cake_wallet/core/new_wallet_type_arguments.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/services/omnichain_wallet/omnichain_wallet_service.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/creation/omnichain_wallet_creation_state.dart";
import "package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/reactions/wallet_utils.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/image_widgets/icon_claster_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/wallet_types.g.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/hardware/device_connection_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

enum OmniChainNetworksMode {
  allNetworks,
  customize,
}

class WalletCreationTypeSelectionPage extends BasePage {
  WalletCreationTypeSelectionPage({
    required this.newWalletTypeArguments,
  });

  final NewWalletTypeArguments newWalletTypeArguments;

  @override
  String get title => "Wallet Networks";

  bool isSupportedHardwareWalletType(WalletType type) {
    if (newWalletTypeArguments.hardwareWalletType == null) return true;

    final supportedConnectionTypes = DeviceConnectionType.supportedConnectionTypes(
      type,
      newWalletTypeArguments.hardwareWalletType!,
      Platform.isIOS,
    );

    return supportedConnectionTypes.isNotEmpty;
  }

  @override
  Widget body(BuildContext context) {
    final flowWalletTypes = availableWalletTypes
        .where((element) => isBIP39Wallet(element) && isSupportedHardwareWalletType(element))
        .toList();

    return BlocProvider(
      create: (_) => OmniChainWalletBloc(
        allWalletTypes: flowWalletTypes.toSet(),
        creationService: getIt.get<OmniChainWalletCreationService>(),
      ),
      child: WalletCreationTypeSelectionPageBody(
        isCreate: newWalletTypeArguments.isCreate,
        availableWalletTypes: flowWalletTypes,
      ),
    );
  }
}

class WalletCreationTypeSelectionPageBody extends StatefulWidget {
  const WalletCreationTypeSelectionPageBody(
      {required this.isCreate, required this.availableWalletTypes, this.onTypeSelected});

  final bool isCreate;
  final List<WalletType> availableWalletTypes;
  final void Function(BuildContext, WalletType)? onTypeSelected;

  @override
  State<WalletCreationTypeSelectionPageBody> createState() =>
      _WalletCreationTypeSelectionPageBodyState();
}

class _WalletCreationTypeSelectionPageBodyState extends State<WalletCreationTypeSelectionPageBody> {
  OmniChainNetworksMode _mode = OmniChainNetworksMode.allNetworks;

  bool get _isCustomizing => _mode == OmniChainNetworksMode.customize;

  OmniChainWalletBloc get _bloc => context.read<OmniChainWalletBloc>();

  @override
  void initState() {
    super.initState();
    context.read<OmniChainWalletBloc>().add(OmniChainWalletTypesSelected());
  }

  void _onModeSelected(OmniChainNetworksMode mode) {
    setState(() => _mode = mode);

    switch (mode) {
      case OmniChainNetworksMode.allNetworks:
        context.read<OmniChainWalletBloc>().add(OmniChainWalletTypesSelected());
        break;
      case OmniChainNetworksMode.customize:
        break;
    }
  }

  void _onTypeToggled(WalletType type, bool isSelected) =>
      _bloc.add(OmniChainWalletTypeToggled(type: type, isSelected: isSelected));

  void _onSelectAll() => _bloc.add(OmniChainWalletTypesSelected());

  void _onUnselectAll() => _bloc.add(OmniChainWalletTypesDeselected());

  Future<void> _continue() async {
    _bloc.add(OmniChainWalletChainSelectionConfirmed());

    await Navigator.of(context).pushNamed(
      Routes.walletCreationDetailsPage,
      arguments: _bloc,
    );

    if (!mounted) return;
    _bloc.add(OmniChainWalletChainSelectionReopened());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<OmniChainWalletBloc, WalletCreationState>(
      buildWhen: (_, current) => current is WalletCreationChainSelection,
      builder: (context, rawState) {
        final state = rawState as WalletCreationChainSelection;

        final canContinue =
            _mode == OmniChainNetworksMode.allNetworks || (_isCustomizing && state.hasAnySelected);

        return Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: IconCluster(
                      iconPaths: [
                        "assets/new-ui/bitcoin_cleanup_outline.svg",
                        "assets/new-ui/monero_cleanup.svg",
                        "assets/new-ui/ethereum_cleanup_outline.svg",
                        "assets/new-ui/more_networks_outline.svg",
                      ],
                      itemSize: 48,
                      spacing: 8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "What networks do you want to use on this wallet?",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HowToChangeNetworksLink(
                    onTap: () => OmniChainHowToChangeNetworksSheet.show(context),
                  ),
                  const SizedBox(height: 24),
                  OmniChainNetworksModeSelector(
                    selectedMode: _mode,
                    onModeSelected: _onModeSelected,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _isCustomizing
                        ? Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: OmniChainNetworksList(
                              types: widget.availableWalletTypes,
                              isSelected: state.isSelected,
                              onTypeToggled: _onTypeToggled,
                              onSelectAll: _onSelectAll,
                              onUnselectAll: _onUnselectAll,
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: FloatingBlurWrapper(
                  child: PrimaryButton(
                    key: const ValueKey("new_wallet_continue_button_key"),
                    onPressed: _continue,
                    text: S.of(context).continue_text,
                    color: theme.colorScheme.primary,
                    textColor: theme.colorScheme.onPrimary,
                    isDisabled: !canContinue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HowToChangeNetworksLink extends StatelessWidget {
  const _HowToChangeNetworksLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      key: const ValueKey("omnichain_how_to_change_networks_key"),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "How to change Network",
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 6),
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class OmniChainNetworksModeSelector extends StatelessWidget {
  const OmniChainNetworksModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
  });

  final OmniChainNetworksMode selectedMode;
  final ValueChanged<OmniChainNetworksMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NewListSections(
      sections: {
        "": [
          ListItemRegularRow(
            keyValue: "omnichain_all_networks_option",
            onTap: () => onModeSelected(OmniChainNetworksMode.allNetworks),
            label: "All Networks",
            subtitle: "Recommended",
            iconPath: "assets/new-ui/chains.svg",
            iconColor: theme.colorScheme.onSurfaceVariant,
            showArrow: false,
            isSelected: selectedMode == OmniChainNetworksMode.allNetworks,
            selectedIconColor: theme.colorScheme.primary,
            mainPadding: const EdgeInsets.symmetric(vertical: 6),
          ),
          ListItemRegularRow(
            keyValue: "omnichain_customize_option",
            onTap: () => onModeSelected(OmniChainNetworksMode.customize),
            label: "Customize",
            iconPath: "assets/new-ui/pencil.svg",
            iconColor: theme.colorScheme.onSurfaceVariant,
            showArrow: false,
            isSelected: selectedMode == OmniChainNetworksMode.customize,
            selectedIconColor: theme.colorScheme.primary,
            mainPadding: const EdgeInsets.symmetric(vertical: 6),
          ),
        ]
      },
    );
  }
}

class OmniChainNetworksList extends StatelessWidget {
  const OmniChainNetworksList({
    required this.types,
    required this.isSelected,
    required this.onTypeToggled,
    this.onSelectAll,
    this.onUnselectAll,
    this.sectionTitle = "Networks",
  });

  final List<WalletType> types;
  final bool Function(WalletType type) isSelected;
  final void Function(WalletType type, bool isSelected) onTypeToggled;
  final VoidCallback? onSelectAll;
  final VoidCallback? onUnselectAll;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Row(
              spacing: 20,
              children: [
                if (onSelectAll != null)
                  GestureDetector(
                    key: const ValueKey("omnichain_select_all_key"),
                    onTap: onSelectAll,
                    child: Text(
                      S.of(context).select_all,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                if (onUnselectAll != null)
                  GestureDetector(
                    key: const ValueKey("omnichain_unselect_all_key"),
                    onTap: onUnselectAll,
                    child: Text(
                      S.of(context).unselect_all,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        NewListSections(
          sections: {
            "": [
              ...types.map(
                (type) => ListItemCheckbox(
                  keyValue: "new_wallet_${type.name}_button_key",
                  iconPath: getCryptoCurrencyIconForWalletListItem(type),
                  label: walletTypeToString(type),
                  subtitle:
                      walletTypeToDescription(type).isEmpty ? null : walletTypeToDescription(type),
                  value: isSelected(type),
                  onChanged: (value) => onTypeToggled(type, value),
                ),
              ),
            ],
          },
        ),
      ],
    );
  }
}

class OmniChainHowToChangeNetworksSheet extends StatelessWidget {
  const OmniChainHowToChangeNetworksSheet({super.key});

  static Future<void> show(BuildContext context) => showCupertinoModalBottomSheet<void>(
        context: context,
        barrierColor: Colors.black.withAlpha(85),
        builder: (_) => const Material(
          child: OmniChainHowToChangeNetworksSheet(),
        ),
      );

  static const _paragraphs = [
    "You can find the Network Selector on the top left corner of your wallet's homescreen.",
    "That way, you can easily change networks without having to navigate to a different tab on Cake Wallet.",
    "If you are familiar with Wallet Groups, this is an improved navigation for them.",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ModalTopBar(
          title: "How to Change Network",
          leadingIcon: const Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).pop,
          leadingSemanticLabel: S.of(context).close,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FrameIconWidget(iconSize: 96),
              const SizedBox(height: 36),
              ..._paragraphs.map(
                (paragraph) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    paragraph,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FrameIconWidget extends StatelessWidget {
  const FrameIconWidget({
    super.key,
    this.iconSize = 48,
  });

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CakeImageWidget(
              imageUrl: "assets/new-ui/frame_icon.svg",
              height: iconSize,
              width: iconSize,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
