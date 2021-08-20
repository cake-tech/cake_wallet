import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/receive/widgets/qr_image.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/view_model/wallet_address_list/wallet_address_list_view_model.dart';

class QRWidget extends StatelessWidget {
  QRWidget(
      {@required this.addressListViewModel,
      this.isAmountFieldShow = false,
      this.amountTextFieldFocusNode,
      this.isBright})
      : amountController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {
    amountController.addListener(() => addressListViewModel.amount =
        _formKey.currentState.validate() ? amountController.text : '');
  }

  final WalletAddressListViewModel addressListViewModel;
  final bool isAmountFieldShow;
  final TextEditingController amountController;
  final FocusNode amountTextFieldFocusNode;
  final GlobalKey<FormState> _formKey;
  final bool isBright;

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_address.png',
        color: Theme.of(context).textTheme.subhead.decorationColor);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Row(children: <Widget>[
          Spacer(flex: 3),
          Observer(
              builder: (_) => Flexible(
                  flex: 5,
                  child: Center(
                      child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    width: 3,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                )
                            ),
                            child: QrImage(
                              data: addressListViewModel.uri.toString(),
                              backgroundColor: isBright ? Colors.black : Colors.transparent,
                              foregroundColor: Theme.of(context).accentTextTheme.
                              display3.backgroundColor,
                            ),
                          ))))),
          Spacer(flex: 3)
        ]),
        if (isAmountFieldShow)
            Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Form(
                            key: _formKey,
                            child: BaseTextFormField(
                                focusNode: amountTextFieldFocusNode,
                                controller: amountController,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  BlacklistingTextInputFormatter(
                                      RegExp('[\\-|\\ ]'))
                                ],
                                textAlign: TextAlign.center,
                                hintText: S.of(context).receive_amount,
                                textColor: Theme.of(context).accentTextTheme.
                                display3.backgroundColor,
                                borderColor: Theme.of(context)
                                    .textTheme
                                    .headline
                                    .decorationColor,
                                validator: AmountValidator(
                                    type: addressListViewModel.type,
                                    isAutovalidate: true),
                                autovalidate: true,
                                placeholderTextStyle: TextStyle(
                                    color: Theme.of(context).hoverColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500))))
                  ],
                ),
              ),
        Padding(
          padding: EdgeInsets.only(top: 16, bottom: 16),
          child: Builder(
              builder: (context) => Observer(
                  builder: (context) => GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: addressListViewModel.address.address));
                          showBar<void>(
                              context, S.of(context).copied_to_clipboard);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                addressListViewModel.address.address,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: copyImage,
                            )
                          ],
                        ),
                      ))),
        ),
        Observer(builder: (_) {
          return addressListViewModel.yatAddress.isNotEmpty
          ? Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text: addressListViewModel.yatAddress));
                    showBar<void>(
                        context, S.of(context).copied_to_clipboard);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Yat Address',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context).accentTextTheme.
                            display3.backgroundColor),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          addressListViewModel.yatAddress,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                          ),
                        )
                      )
                    ]
                  )
                )),
          )
          : Container();
        })
      ],
    );
  }
}
