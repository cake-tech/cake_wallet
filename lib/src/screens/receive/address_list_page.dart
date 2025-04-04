import 'package:cake_wallet/src/screens/receive/widgets/address_list.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';

class AddressListPage extends BasePage {
  AddressListPage(this.addressListViewModel);

  final WalletAddressListViewModel addressListViewModel;

  @override
  String get title => S.current.accounts_subaddresses;

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          AddressList(
            addressListViewModel: addressListViewModel,
            currentTheme: currentTheme,
            onSelect: (String address) async {
              Navigator.of(context).pop(address);
            },
          ),
        ],
      ),
    );
  }
}
