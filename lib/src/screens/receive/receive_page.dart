import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/screens/monero_accounts/monero_account_list_page.dart';
import 'package:cake_wallet/src/screens/receive/widgets/header_tile.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/src/screens/receive/widgets/address_cell.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_account_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_header.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_item.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';

class ReceivePage extends BasePage {
  ReceivePage({this.addressListViewModel})
      : amountController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    amountController.addListener(() => addressListViewModel.amount =
        _formKey.currentState.validate() ? amountController.text : '');
  }

  final WalletAddressListViewModel addressListViewModel;
  final TextEditingController amountController;
  final GlobalKey<FormState> _formKey;

  @override
  Color get backgroundLightColor => Colors.transparent;

  @override
  Color get backgroundDarkColor => Colors.transparent;

  @override
  Widget Function(BuildContext, Widget) get rootWrapper =>
      (BuildContext context, Widget scaffold) => Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).primaryColor
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: scaffold);

  @override
  Widget middle(BuildContext context) => Text(
        S.of(context).receive,
        style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryTextTheme.title.color),
      );

  @override
  Widget trailing(BuildContext context) {
    final shareImage = Image.asset('assets/images/share.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return SizedBox(
      height: 20.0,
      width: 14.0,
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
    final copyImage = Image.asset('assets/images/copy_content.png',
        color: Theme.of(context).primaryTextTheme.title.color);

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          SizedBox(height: 25),
          Row(children: <Widget>[
            Spacer(flex: 4),
            Observer(
                builder: (_) => Flexible(
                    flex: 6,
                    child: Center(
                        child: AspectRatio(
                            aspectRatio: 1.0,
                            child: QrImage(
                              data: addressListViewModel.uri.toString(),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Theme.of(context)
                                  .primaryTextTheme
                                  .display4
                                  .color,
                            ))))),
            Spacer(flex: 4)
          ]),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 40, 24, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Form(
                        key: _formKey,
                        child: BaseTextFormField(
                            controller: amountController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              BlacklistingTextInputFormatter(
                                  RegExp('[\\-|\\ |\\,]'))
                            ],
                            textAlign: TextAlign.center,
                            hintText: S.of(context).receive_amount,
                            borderColor: Theme.of(context)
                                .primaryTextTheme
                                .headline5
                                .color
                                .withOpacity(0.4),
                            validator: AmountValidator(),
                            autovalidate: true,
                            placeholderTextStyle: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .headline5
                                    .color,
                                fontSize: 20,
                                fontWeight: FontWeight.w600))))
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 24, right: 24, bottom: 40, top: 40),
            child: Builder(
                builder: (context) => Observer(
                    builder: (context) => GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(
                                text: addressListViewModel.address.address));
                            Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(
                                S.of(context).copied_to_clipboard,
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(milliseconds: 500),
                            ));
                          },
                          child: Container(
                            height: 48,
                            padding: EdgeInsets.only(left: 24, right: 24),
                            decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(24)),
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .overline
                                    .color),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    addressListViewModel.address.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .primaryTextTheme
                                            .title
                                            .color),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: copyImage,
                                )
                              ],
                            ),
                          ),
                        ))),
          ),
          Observer(
              builder: (_) => ListView.separated(
                  separatorBuilder: (context, _) =>
                      Divider(height: 1, color: Theme.of(context).dividerColor),
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
                            color:
                                Theme.of(context).primaryTextTheme.title.color,
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
                            color:
                                Theme.of(context).primaryTextTheme.title.color,
                          ));
                    }

                    if (item is WalletAddressListItem) {
                      cell = Observer(
                          builder: (_) => AddressCell.fromItem(item,
                              isCurrent: item.address ==
                                  addressListViewModel.address.address,
                              onTap: (_) => addressListViewModel.address = item,
                              onEdit: () => Navigator.of(context).pushNamed(
                                  Routes.newSubaddress,
                                  arguments: item)));
                    }

                    return index != 0
                        ? cell
                        : ClipRRect(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24)),
                            child: cell,
                          );
                  })),
        ],
      ),
    );
  }
}
