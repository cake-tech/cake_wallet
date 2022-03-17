import 'package:cake_wallet/utils/payment_request.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class SendTemplatePage extends BasePage {
  SendTemplatePage({@required this.sendTemplateViewModel}) {
    sendTemplateViewModel.output.reset();
  }

  final SendTemplateViewModel sendTemplateViewModel;
  final _addressController = TextEditingController();
  final _cryptoAmountController = TextEditingController();
  final _fiatAmountController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _cryptoAmountFocus = FocusNode();
  final FocusNode _fiatAmountFocus = FocusNode();

  bool _effectsInstalled = false;

  @override
  String get title => S.current.exchange_new_template;

  @override
  Color get titleColor => Colors.white;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget body(BuildContext context) {
    _setEffects(context);

    return KeyboardActions(
        config: KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
            keyboardBarColor:
                Theme.of(context).accentTextTheme.body2.backgroundColor,
            nextFocus: false,
            actions: [
              KeyboardActionsItem(
                focusNode: _cryptoAmountFocus,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              ),
              KeyboardActionsItem(
                focusNode: _fiatAmountFocus,
                toolbarButtons: [(_) => KeyboardDoneButton()],
              )
            ]),
        child: Container(
          height: 0,
          color: Theme.of(context).backgroundColor,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                gradient: LinearGradient(colors: [
                  Theme.of(context).primaryTextTheme.subhead.color,
                  Theme.of(context).primaryTextTheme.subhead.decorationColor,
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, 90, 24, 32),
                      child: Column(
                        children: <Widget>[
                          BaseTextFormField(
                            controller: _nameController,
                            hintText: S.of(context).send_name,
                            borderColor: Theme.of(context)
                                .primaryTextTheme
                                .headline
                                .color,
                            textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                            placeholderTextStyle: TextStyle(
                                color: Theme.of(context)
                                    .primaryTextTheme
                                    .headline
                                    .decorationColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14),
                            validator: sendTemplateViewModel.templateValidator,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: AddressTextField(
                              controller: _addressController,
                              onURIScanned: (uri) {
                                final paymentRequest = PaymentRequest.fromUri(uri);
                                _addressController.text = paymentRequest.address;
                                _cryptoAmountController.text = paymentRequest.amount;
                              },
                              options: [
                                AddressTextFieldOption.paste,
                                AddressTextFieldOption.qrCode,
                                AddressTextFieldOption.addressBook
                              ],
                              buttonColor: Theme.of(context)
                                  .primaryTextTheme
                                  .display1
                                  .color,
                              borderColor: Theme.of(context)
                                  .primaryTextTheme
                                  .headline
                                  .color,
                              textStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                              hintStyle: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .primaryTextTheme
                                      .headline
                                      .decorationColor),
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: BaseTextFormField(
                                  focusNode: _cryptoAmountFocus,
                                  controller: _cryptoAmountController,
                                  keyboardType: TextInputType.numberWithOptions(
                                      signed: false, decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp('[\\-|\\ ]'))
                                  ],
                                  prefixIcon: Padding(
                                    padding: EdgeInsets.only(top: 9),
                                    child: Text(
                                        sendTemplateViewModel.currency.title +
                                            ':',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        )),
                                  ),
                                  hintText: '0.0000',
                                  borderColor: Theme.of(context)
                                      .primaryTextTheme
                                      .headline
                                      .color,
                                  textStyle: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                  placeholderTextStyle: TextStyle(
                                      color: Theme.of(context)
                                          .primaryTextTheme
                                          .headline
                                          .decorationColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14),
                                  validator:
                                      sendTemplateViewModel.amountValidator)),
                          Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: BaseTextFormField(
                                focusNode: _fiatAmountFocus,
                                controller: _fiatAmountController,
                                keyboardType: TextInputType.numberWithOptions(
                                    signed: false, decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                      RegExp('[\\-|\\ ]'))
                                ],
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(top: 9),
                                  child: Text(
                                      sendTemplateViewModel.fiat.title + ':',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      )),
                                ),
                                hintText: '0.00',
                                borderColor: Theme.of(context)
                                    .primaryTextTheme
                                    .headline
                                    .color,
                                textStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                                placeholderTextStyle: TextStyle(
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .headline
                                        .decorationColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14),
                              )),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            bottomSectionPadding:
                EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: PrimaryButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  sendTemplateViewModel.addTemplate(
                      name: _nameController.text,
                      address: _addressController.text,
                      cryptoCurrency: sendTemplateViewModel.currency.title,
                      amount: _cryptoAmountController.text);
                  Navigator.of(context).pop();
                }
              },
              text: S.of(context).save,
              color: Colors.green,
              textColor: Colors.white,
            ),
          ),
        ));
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    final output = sendTemplateViewModel.output;

    reaction((_) => output.fiatAmount, (String amount) {
      if (amount != _fiatAmountController.text) {
        _fiatAmountController.text = amount;
      }
    });

    reaction((_) => output.cryptoAmount, (String amount) {
      if (amount != _cryptoAmountController.text) {
        _cryptoAmountController.text = amount;
      }
    });

    reaction((_) => output.address, (String address) {
      if (address != _addressController.text) {
        _addressController.text = address;
      }
    });

    _cryptoAmountController.addListener(() {
      final amount = _cryptoAmountController.text;

      if (amount != output.cryptoAmount) {
        output.setCryptoAmount(amount);
      }
    });

    _fiatAmountController.addListener(() {
      final amount = _fiatAmountController.text;

      if (amount != output.fiatAmount) {
        output.setFiatAmount(amount);
      }
    });

    _addressController.addListener(() {
      final address = _addressController.text;

      if (output.address != address) {
        output.address = address;
      }
    });

    _effectsInstalled = true;
  }
}
