import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/header_tile.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_cell.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_widget.dart';

class ReceivePage extends BasePage {
  ReceivePage({this.addressListViewModel});

  final WalletAddressListViewModel addressListViewModel;

  @override
  String get title => S.current.receive;

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Color get titleColor => Colors.white;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
          (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Theme.of(context).accentColor,
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).primaryColor,
              ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft)),
          child: scaffold);

  @override
  Widget trailing(BuildContext context) {
    final shareImage = Image.asset('assets/images/share.png',
        color: Colors.white);

    return SizedBox(
      height: 20.0,
      width: 20.0,
      child: ButtonTheme(
        minWidth: double.minPositive,
        child: FlatButton(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          padding: EdgeInsets.all(0),
          onPressed: () => Share.text(S.current.share_address,
            addressListViewModel.address.address, 'text/plain'),
          child: shareImage),
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(24, 80, 24, 40),
            child: QRWidget(
              addressListViewModel: addressListViewModel,
              isAmountFieldShow: true,
            ),
          ),
          Observer(
              builder: (_) => ListView.separated(
                  separatorBuilder: (context, _) =>
                      Container(
                          height: 1,
                          color: Theme.of(context).dividerColor),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: addressListViewModel.items.length,
                  itemBuilder: (context, index) {
                    final item = addressListViewModel.items[index];
                    Widget cell = Container();

                    if (item is WalletAccountListHeader) {
                      cell = HeaderTile(
                          onTap: () async => await showDialog<void>(
                              context: context,
                              builder: (_) => getIt.get<MoneroAccountListPage>()),
                          title: addressListViewModel.accountLabel,
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Theme.of(context).textTheme.display1.color,
                          ));
                    }

                    if (item is WalletAddressListHeader) {
                      cell = HeaderTile(
                          onTap: () => Navigator.of(context)
                              .pushNamed(Routes.newSubaddress),
                          title: S.of(context).addresses,
                          icon: Icon(
                            Icons.add,
                            size: 20,
                            color: Theme.of(context).textTheme.display1.color,
                          ));
                    }

                    if (item is WalletAddressListItem) {
                      cell = Observer(
                          builder: (_) {
                            final isCurrent = item.address ==
                                addressListViewModel.address.address;
                            final backgroundColor = isCurrent
                                ? Theme.of(context).textTheme.display3.decorationColor
                                : Theme.of(context).textTheme.display2.decorationColor;
                            final textColor = isCurrent
                                ? Theme.of(context).textTheme.display3.color
                                : Theme.of(context).textTheme.display2.color;

                            return AddressCell.fromItem(item,
                                isCurrent: isCurrent,
                                backgroundColor: backgroundColor,
                                textColor: textColor,
                                onTap: (_) => addressListViewModel.address = item,
                                onEdit: () => Navigator.of(context).pushNamed(
                                    Routes.newSubaddress,
                                    arguments: item));
                          }
                      );
                    }

                    return index != 0
                        ? cell
                        : ClipRRect(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30)),
                            child: cell,
                          );
                  })),
        ],
      ),
    );
  }
}
