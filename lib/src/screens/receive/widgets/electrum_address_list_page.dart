import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/receive/widgets/electrum_address_tile.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/picker_inner_wrapper_widget.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ElectrumAddressListPage extends StatefulWidget {
  const ElectrumAddressListPage({required WalletBase wallet})
      : this._wallet = wallet;

  final WalletBase _wallet;

  @override
  State<ElectrumAddressListPage> createState() =>
      _ElectrumAddressListPageState(wallet: _wallet);
}

class _ElectrumAddressListPageState extends State<ElectrumAddressListPage> {
  _ElectrumAddressListPageState({required WalletBase wallet})
      : this._wallet = wallet is ElectrumWallet ? wallet : null;

  final ElectrumWallet? _wallet;
  final ScrollController controller = ScrollController();
  late TextEditingController searchController;
  late List<BitcoinAddressRecord> filteredAddresses;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredAddresses = getAddresses();
    searchController.addListener(() {
      filterAddresses();
    });
  }

  List<BitcoinAddressRecord> getAddresses() =>
      _wallet?.walletAddresses.usedAddressList ?? [];

  void filterAddresses() {
    String searchText = searchController.text.toLowerCase();
    setState(() {
      filteredAddresses = getAddresses().where((address) {
        return address.address.toLowerCase().contains(searchText);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double itemHeight = 65;
    double buttonHeight = 62;

    return getAddresses().isEmpty
        ? GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: AlertBackground(child: PlaceholderWidget(context)))
        : PickerInnerWrapperWidget(
            title: 'Address List',
            itemsHeight: (itemHeight * filteredAddresses.length) + buttonHeight,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                child: SearchBarWidget(
                    searchController: searchController,
                    borderRadius: 12,
                    hintText: 'Search address'),
              ),
              Expanded(
                  child: Scrollbar(
                controller: controller,
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  controller: controller,
                  separatorBuilder: (context, index) =>
                      const HorizontalSectionDivider(),
                  itemCount: filteredAddresses.length,
                  itemBuilder: (context, index) {
                    final item = filteredAddresses[index];
                    return ElectrumAddressTile(
                      address: item.address,
                      isChange: item.isHidden,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: item.address));
                        showBar<void>(
                            context,
                            S.of(context).transaction_details_copied(
                                S.of(context).address));
                      },
                    );
                  },
                ),
              )),
            ],
          );
  }
}

Widget PlaceholderWidget(BuildContext context) {
  return Center(
    child: Text(
      'Your previous used addresses will appear here',
      style: TextStyle(fontSize: 14, color: Colors.white),
    ),
  );
}
