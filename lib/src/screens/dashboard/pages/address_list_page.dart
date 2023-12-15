import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_list_item.dart';
import 'package:cake_wallet/src/widgets/search_bar_widget.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddressListPage extends BasePage {
  AddressListPage({required WalletBase wallet}) : this._wallet = wallet;

  @override
  String get title => toBeginningOfSentenceCase(S.current.address_list) ?? '';

  final WalletBase _wallet;

  Widget body(BuildContext context) => AddressListBody(wallet: _wallet);
}

class AddressListBody extends StatefulWidget {
  const AddressListBody({required this.wallet});

  final WalletBase wallet;

  @override
  State<AddressListBody> createState() => _AddressListBodyState(wallet: wallet);
}

class _AddressListBodyState extends State<AddressListBody> {
  _AddressListBodyState({required this.wallet});

  final WalletBase wallet;
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

  List<BitcoinAddressRecord> getAddresses() {
    return (widget.wallet as ElectrumWallet).walletAddresses.usedAddressList;
  }

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
  Widget build(BuildContext context) => (wallet is ElectrumWallet)
      ? Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SearchBarWidget(
                  searchController: searchController,
                  borderRadius: 12,
                  searchIconColor: Theme.of(context).primaryColor,
                  hintText: S.of(context).search_address),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ListView.separated(
                  itemCount: filteredAddresses.length,
                  separatorBuilder: (_, __) => SizedBox(height: 15),
                  itemBuilder: (_, int index) {
                    final item = filteredAddresses[index];
                    return AddressListItem(
                        address: item.address, isChange: item.isHidden);
                  },
                ),
              ),
            ),
          ],
        )
      : Container();
}
