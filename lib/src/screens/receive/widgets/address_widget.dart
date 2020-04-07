import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/screens/receive/qr_image.dart';

class AddressWidget extends StatefulWidget {
  AddressWidget({@required this.isSubaddress});

  final bool isSubaddress;

  @override
  AddressWidgetState createState() => AddressWidgetState(isSubaddress);
}

class AddressWidgetState extends State<AddressWidget> {
  AddressWidgetState(this._isSubaddress);

  final amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _isSubaddress;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletStore = Provider.of<WalletStore>(context);

    amountController.addListener(() {
      if (_formKey.currentState.validate()) {
        walletStore.onChangedAmountValue(amountController.text);
      } else {
        walletStore.onChangedAmountValue('');
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Observer(builder: (_) {
          return Row(
            children: <Widget>[
              Spacer(
                flex: 1,
              ),
              Flexible(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      color: Colors.white,
                      child: QrImage(
                        data: _isSubaddress
                        ? walletStore.subaddress.address + walletStore.amountValue
                        : walletStore.address + walletStore.amountValue,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  )),
              Spacer(
                flex: 1,
              )
            ],
          );
        }),
        Observer(builder: (_) {
          return Row(
            children: <Widget>[
              Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: _isSubaddress
                              ? walletStore.subaddress.address
                              : walletStore.address
                          ));
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text(
                              S.of(context).copied_to_clipboard,
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                          ));
                        },
                        child: Text(
                          _isSubaddress
                          ? walletStore.subaddress.address
                          : walletStore.address,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .title
                                  .color),
                        ),
                      ),
                    ),
                  ))
            ],
          );
        }),
        Row(
          children: <Widget>[
            Expanded(
                child: Form(
                    key: _formKey,
                    child: TextFormField(
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        BlacklistingTextInputFormatter(
                            RegExp('[\\-|\\ |\\,]'))
                      ],
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                      decoration: InputDecoration(
                          hintStyle: TextStyle(
                              color: Theme.of(context).hintColor),
                          hintText: S.of(context).amount,
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Palette.cakeGreen, width: 2.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).focusColor,
                                  width: 1.0))),
                      validator: (value) {
                        walletStore.validateAmount(value);
                        return walletStore.errorMessage;
                      },
                      autovalidate: true,
                      controller: amountController,
                    )))
          ],
        )
      ],
    );
  }
}