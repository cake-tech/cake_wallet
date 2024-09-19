import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/screens/receive/widgets/currency_input_field.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/send/template_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:mobx/mobx.dart';

class SendTemplateCard extends StatelessWidget {
  SendTemplateCard(
      {super.key,
      required this.template,
      required this.index,
      required this.sendTemplateViewModel});

  final TemplateViewModel template;
  final int index;
  final SendTemplateViewModel sendTemplateViewModel;

  final _addressController = TextEditingController();
  final _cryptoAmountController = TextEditingController();
  final _fiatAmountController = TextEditingController();
  final _nameController = TextEditingController();
  final FocusNode _cryptoAmountFocus = FocusNode();
  final FocusNode _fiatAmountFocus = FocusNode();

  bool _effectsInstalled = false;

  @override
  Widget build(BuildContext context) {
    _setEffects(context);

    return Container(
      decoration: BoxDecoration(
          borderRadius:
              BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          gradient: LinearGradient(colors: [
            Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
            Theme.of(context).extension<SendPageTheme>()!.secondGradientColor
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(24, 90, 24, 32),
            child: Column(
              children: <Widget>[
                if (index == 0)
                  BaseTextFormField(
                      controller: _nameController,
                      hintText: sendTemplateViewModel.recipients.length > 1
                          ? S.of(context).template_name
                          : S.of(context).send_name,
                      borderColor:
                          Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor,
                      textStyle:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                      placeholderTextStyle: TextStyle(
                          color: Theme.of(context).extension<SendPageTheme>()!.textFieldHintColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 14),
                      validator: sendTemplateViewModel.templateValidator),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Observer(builder: (context) {
                    return AddressTextField(
                      selectedCurrency: template.selectedCurrency,
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
                      onPushPasteButton: (context) async {
                        template.output.resetParsedAddress();
                        await template.output.fetchParsedAddress(context);
                      },
                      onPushAddressBookButton: (context) async {
                        template.output.resetParsedAddress();
                        await template.output.fetchParsedAddress(context);
                      },
                      buttonColor:
                          Theme.of(context).extension<SendPageTheme>()!.textFieldButtonColor,
                      borderColor:
                          Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor,
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).extension<SendPageTheme>()!.textFieldHintColor,
                      ),
                      validator: sendTemplateViewModel.addressValidator,
                    );
                  }),
                ),
                Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) template.setCryptoCurrency(true);
                  },
                  child: Column(
                    children: [
                      Observer(
                          builder: (context) => CurrencyAmountTextField(
                              selectedCurrency: template.selectedCurrency.title,
                              amountFocusNode: _cryptoAmountFocus,
                              amountController: _cryptoAmountController,
                              isSelected: template.isCryptoSelected,
                              tag: template.selectedCurrency.tag,
                              isPickerEnable: sendTemplateViewModel.hasMultipleTokens,
                              onTapPicker: () => _presentPicker(context),
                              currencyValueValidator: sendTemplateViewModel.amountValidator,
                              isAmountEditable: true)),
                      Divider(
                          height: 1,
                          color: Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor)
                    ],
                  ),
                ),
                Focus(
                  onFocusChange: (hasFocus) {
                    if (hasFocus) template.setCryptoCurrency(false);
                  },
                  child: Column(
                    children: [
                      Observer(
                          builder: (context) => CurrencyAmountTextField(
                              selectedCurrency: sendTemplateViewModel.fiatCurrency,
                              amountFocusNode: _fiatAmountFocus,
                              amountController: _fiatAmountController,
                              isSelected: !template.isCryptoSelected,
                              hintText: '0.00',
                              isAmountEditable: true)),
                      Divider(
                          height: 1,
                          color: Theme.of(context).extension<SendPageTheme>()!.textFieldBorderColor)
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _setEffects(BuildContext context) {
    if (_effectsInstalled) {
      return;
    }

    final output = template.output;

    if (template.address.isNotEmpty) {
      _addressController.text = template.address;
    }
    if (template.name.isNotEmpty) {
      _nameController.text = template.name;
    }
    if (template.output.cryptoAmount.isNotEmpty) {
      _cryptoAmountController.text = template.output.cryptoAmount;
    }
    if (template.output.fiatAmount.isNotEmpty) {
      _fiatAmountController.text = template.output.fiatAmount;
    }

    _addressController.addListener(() {
      final address = _addressController.text;

      if (template.address != address) {
        template.address = address;
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
    _nameController.addListener(() {
      final name = _nameController.text;

      if (name != template.name) {
        template.name = name;
      }
    });

    reaction((_) => template.address, (String address) {
      if (address != _addressController.text) {
        _addressController.text = address;
      }
    });
    reaction((_) => output.cryptoAmount, (String amount) {
      if (amount != _cryptoAmountController.text) {
        _cryptoAmountController.text = amount;
      }
    });
    reaction((_) => output.fiatAmount, (String amount) {
      if (amount != _fiatAmountController.text) {
        _fiatAmountController.text = amount;
      }
    });
    reaction((_) => template.name, (String name) {
      if (name != _nameController.text) {
        _nameController.text = name;
      }
    });

    _effectsInstalled = true;
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (_) => CurrencyPicker(
        selectedAtIndex: sendTemplateViewModel.walletCurrencies.indexOf(template.selectedCurrency),
        items: sendTemplateViewModel.walletCurrencies,
        hintText: S.of(context).search_currency,
        onItemSelected: (Currency cur) => template.changeSelectedCurrency(cur as CryptoCurrency),
      ),
    );
  }
}
