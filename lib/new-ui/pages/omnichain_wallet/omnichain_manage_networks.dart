import 'package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart';
import 'package:cake_wallet/new-ui/modal_navigator.dart';
import 'package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart';
import 'package:cake_wallet/new-ui/widgets/new_search_bar.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/reactions/wallet_utils.dart';
import 'package:cake_wallet/src/widgets/new_list_row/new_list_section.dart';
import 'package:cake_wallet/wallet_types.g.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';

class OmniChainManageNetworksPage extends StatelessWidget {
  const OmniChainManageNetworksPage({
    super.key,
    this.availableNetworks,
    this.selectedNetworks = const {},
    this.onChanged,
  });

  final List<WalletType>? availableNetworks;
  final Set<WalletType> selectedNetworks;
  final ValueChanged<Set<WalletType>>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ModalNavigator(
      parentContext: context,
      rootPage: OmniChainManageNetworksMainPage(
        availableNetworks: availableNetworks ?? availableWalletTypes,
        selectedNetworks: selectedNetworks,
        onChanged: onChanged,
      ),
    );
  }
}

class OmniChainManageNetworksMainPage extends StatefulWidget {
  const OmniChainManageNetworksMainPage({
    super.key,
    required this.availableNetworks,
    required this.selectedNetworks,
    this.onChanged,
  });

  final List<WalletType> availableNetworks;
  final Set<WalletType> selectedNetworks;
  final ValueChanged<Set<WalletType>>? onChanged;

  @override
  State<OmniChainManageNetworksMainPage> createState() => _OmniChainManageNetworksMainPageState();
}

class _OmniChainManageNetworksMainPageState extends State<OmniChainManageNetworksMainPage> {
  final TextEditingController _searchController = TextEditingController();

  late Set<WalletType> selectedNetworks;
  late List<WalletType> filteredNetworks;

  static const _popularTypes = {
    WalletType.monero,
    WalletType.bitcoin,
    WalletType.ethereum,
    WalletType.solana,
    WalletType.base,
  };

  @override
  void initState() {
    super.initState();

    selectedNetworks = Set<WalletType>.from(widget.selectedNetworks);
    filteredNetworks = _sortNetworks(widget.availableNetworks);

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      filteredNetworks = query.isEmpty
          ? _sortNetworks(widget.availableNetworks)
          : _sortNetworks(widget.availableNetworks)
              .where((type) => walletTypeToString(type).toLowerCase().contains(query))
              .toList();
    });
  }

  List<WalletType> _sortNetworks(Iterable<WalletType> networks) {
    final result = networks.toSet().toList();
    result.sort((a, b) => walletTypeToString(a).compareTo(walletTypeToString(b)));
    return result;
  }

  List<WalletType> get popularNetworks {
    return _popularTypes.where((type) => filteredNetworks.contains(type)).toList();
  }

  List<WalletType> get otherNetworks {
    return filteredNetworks.where((type) => !_popularTypes.contains(type)).toList();
  }

  void _toggleNetwork(WalletType type, bool value) {
    setState(() {
      if (value) {
        if (isBIP39Wallet(type)) {
          selectedNetworks.removeWhere((selectedType) => !isBIP39Wallet(selectedType));
          selectedNetworks.add(type);
        } else {
          selectedNetworks
            ..clear()
            ..add(type);
        }
      } else {
        selectedNetworks.remove(type);
      }
    });

    widget.onChanged?.call(Set<WalletType>.from(selectedNetworks));
  }

  ListItemCheckbox _networkItem(WalletType type, String keyPrefix) {
    final labelIcon = isEVMCompatibleChain(type) && type != WalletType.ethereum
        ? CryptoCurrency.eth.flatIconPath
        : null;

    final typeDesc = walletTypeToDescription(type);
    final typeSuffix = isBIP39Wallet(type) ? '' : 'Single Wallet Only';

    final subtitleParts = [
      if (typeDesc.isNotEmpty) typeDesc,
      if (typeSuffix.isNotEmpty) typeSuffix,
    ];

    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' · ');

    return ListItemCheckbox(
      keyValue: '${keyPrefix}_${type.name}_button_key',
      label: walletTypeToString(type),
      labelIconPath: labelIcon,
      iconPath: getCryptoCurrencyIconForWalletListItem(type),
      subtitle: subtitle,
      value: selectedNetworks.contains(type),
      onChanged: (value) => _toggleNetwork(type, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModalTopBar(
          title: 'Manage networks',
          leadingIcon: const Icon(Icons.arrow_back_ios_new_outlined),
          onLeadingPressed: Navigator.of(context, rootNavigator: true).pop,
          onTrailingPressed: () {},
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 88),
                  child: NewListSections(
                    showHeader: true,
                    sections: {
                      'Popular': [
                        ...popularNetworks.map(
                          (type) => _networkItem(type, 'manage_network_popular'),
                        ),
                      ],
                      'A to Z': [
                        ...otherNetworks.map(
                          (type) => _networkItem(type, 'manage_network'),
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
                        child: NewSearchBar(
                          controller: _searchController,
                          height: 40,
                        ),
                      ),
                    ),
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
