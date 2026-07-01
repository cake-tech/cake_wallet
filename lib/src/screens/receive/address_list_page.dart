import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_list.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AddressListPage extends StatelessWidget {
  AddressListPage(this.addressListViewModel);

  final WalletAddressListViewModel addressListViewModel;

  @override
  String get title => S.current.accounts_subaddresses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModalTopBar(
          title: S.of(context).accounts_subaddresses,
          leadingIcon: Icon(Icons.arrow_back_ios_new),
          onLeadingPressed: Navigator.of(context).pop,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: ModalScrollController.of(context),
            child: Column(
              children: <Widget>[
                AddressList(
                  addressListViewModel: addressListViewModel,
                  onSelect: (String address) async {
                    Navigator.of(context).pop(address);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
