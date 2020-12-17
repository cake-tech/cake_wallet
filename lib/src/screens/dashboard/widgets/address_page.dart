import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_widget.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';

class AddressPage extends StatelessWidget {
  AddressPage({@required this.addressListViewModel});

  final WalletAddressListViewModel addressListViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: <Widget>[
          Expanded(
              child: Center(
            child: QRWidget(addressListViewModel: addressListViewModel),
          )),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(Routes.receive),
            child: Container(
              height: 50,
              padding: EdgeInsets.only(left: 24, right: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  border: Border.all(
                      color: Theme.of(context).textTheme.subhead.color,
                      width: 1),
                  color: Theme.of(context).buttonColor),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    addressListViewModel.hasAccounts
                        ? S.of(context).accounts_subaddresses
                        : S.of(context).addresses,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
