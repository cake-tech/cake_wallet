import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_bloc.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_event.dart";
import "package:cake_wallet/new-ui/viewmodels/omnichain_wallet/managing/omnichain_wallet_managing_state.dart";
import "package:cake_wallet/new-ui/widgets/floating_blur_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/new_search_bar.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/reactions/wallet_connect.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:fluttertoast/fluttertoast.dart";

class OmniChainManageNetworksMainPage extends StatefulWidget {
  const OmniChainManageNetworksMainPage({
    required this.availableNetworks,
    required this.selectedNetworks,
    super.key,
  });

  final List<WalletType> availableNetworks;
  final Set<WalletType> selectedNetworks;

  @override
  State<OmniChainManageNetworksMainPage> createState() => _OmniChainManageNetworksMainPageState();
}

class _OmniChainManageNetworksMainPageState extends State<OmniChainManageNetworksMainPage> {
  final TextEditingController _searchController = TextEditingController();

  late final Set<WalletType> _locked; // already in the group — always checked, never removable
  final Set<WalletType> _added = {}; // added this session
  late List<WalletType> filteredNetworks;

  WalletType? _inFlightType;

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
    _locked = Set<WalletType>.from(widget.selectedNetworks);
    filteredNetworks = _sortNetworks(widget.availableNetworks);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isChecked(WalletType t) => _locked.contains(t) || _added.contains(t);

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

  List<WalletType> get popularNetworks => _popularTypes.where(filteredNetworks.contains).toList();

  List<WalletType> get otherNetworks =>
      filteredNetworks.where((t) => !_popularTypes.contains(t)).toList();

  void _onNetworkTapped(WalletType type) {
    if (_isChecked(type)) return; // add-only: already in the group / just added

    setState(() {
      _added.add(type);
      _inFlightType = type;
    });

    context.read<OmniChainWalletManagingBloc>().add(
          OmniChainWalletManagingNetworksAdded({type}),
        );
  }

  Future<void> _showToast(String msg) async {
    try {
      await Fluttertoast.showToast(
        msg: msg,
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.85),
      );
    } catch (_) {}
  }

  ListItemCheckbox _networkItem(WalletType type, String keyPrefix) {
    final labelIcon = isEVMCompatibleChain(type) && type != WalletType.ethereum
        ? CryptoCurrency.eth.flatIconPath
        : null;

    return ListItemCheckbox(
      keyValue: "${keyPrefix}_${type.name}_button_key",
      label: walletTypeToString(type),
      labelIconPath: labelIcon,
      iconPath: getCryptoCurrencyIconForWalletListItem(type),
      subtitle: walletTypeToDescription(type).isNotEmpty ? walletTypeToDescription(type) : null,
      value: _isChecked(type),
      onChanged: (_) => _onNetworkTapped(type),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<OmniChainWalletManagingBloc, OmniChainWalletManagingState>(
        listenWhen: (prev, curr) =>
            prev.isLoading != curr.isLoading || (curr.error != null && curr.error != prev.error),
        listener: (context, state) {
          if (state.isLoading) return;

          final finished = _inFlightType;
          _inFlightType = null;

          if (state.error != null) {
            if (finished != null) {
              setState(() => _added.remove(finished));
            }
            _showToast(state.error!);
          } else if (finished != null) {
            _showToast("${walletTypeToString(finished)} network added");
          }
        },
        builder: (context, state) {
          final isBusy = state.isLoading;

          return Column(
            children: [
              ModalTopBar(
                title: "Manage networks",
                leadingIcon: const Icon(Icons.arrow_back_ios_new),
                leadingSemanticLabel: S.of(context).seed_alert_back,
                onLeadingPressed: isBusy ? () {} : () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: IgnorePointer(
                  ignoring: isBusy,
                  child: Opacity(
                    opacity: isBusy ? 0.6 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 88),
                            child: NewListSections(
                              showHeader: true,
                              sections: {
                                "Popular": [
                                  ...popularNetworks.map(
                                    (t) => _networkItem(t, "manage_network_popular"),
                                  ),
                                ],
                                "A to Z": [
                                  ...otherNetworks.map((t) => _networkItem(t, "manage_network")),
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
                                  horizontalPadding: 0,
                                  child: NewSearchBar(controller: _searchController, height: 40),
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
            ],
          );
        },
      );
}
