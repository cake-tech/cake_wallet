import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';

class ExchangeCard extends StatefulWidget {
  ExchangeCard(
      {Key key,
      this.title = '',
      this.initialCurrency,
      this.initialAddress,
      this.initialWalletName,
      this.initialIsAmountEditable,
      this.initialIsAddressEditable,
      this.isAmountEstimated,
      this.hasRefundAddress = false,
      this.isMoneroWallet = false,
      this.currencies,
      this.onCurrencySelected,
      this.imageArrow,
      this.currencyButtonColor = Colors.transparent,
      this.addressButtonsColor = Colors.transparent,
      this.borderColor = Colors.transparent,
      this.currencyValueValidator,
      this.addressTextFieldValidator,
      this.amountFocusNode,
      this.addressFocusNode,
      this.hasAllAmount = false,
      this.allAmount,
      this.onPushPasteButton})
      : super(key: key);

  final List<CryptoCurrency> currencies;
  final Function(CryptoCurrency) onCurrencySelected;
  final String title;
  final CryptoCurrency initialCurrency;
  final String initialWalletName;
  final String initialAddress;
  final bool initialIsAmountEditable;
  final bool initialIsAddressEditable;
  final bool isAmountEstimated;
  final bool hasRefundAddress;
  final bool isMoneroWallet;
  final Image imageArrow;
  final Color currencyButtonColor;
  final Color addressButtonsColor;
  final Color borderColor;
  final FormFieldValidator<String> currencyValueValidator;
  final FormFieldValidator<String> addressTextFieldValidator;
  final FocusNode amountFocusNode;
  final FocusNode addressFocusNode;
  final bool hasAllAmount;
  final Function allAmount;
  final Function(BuildContext context) onPushPasteButton;

  @override
  ExchangeCardState createState() => ExchangeCardState();
}

class ExchangeCardState extends State<ExchangeCard> {
  final addressController = TextEditingController();
  final amountController = TextEditingController();

  String _title;
  String _min;
  String _max;
  CryptoCurrency _selectedCurrency;
  String _walletName;
  bool _isAmountEditable;
  bool _isAddressEditable;
  bool _isAmountEstimated;
  bool _isMoneroWallet;

  @override
  void initState() {
    _title = widget.title;
    _isAmountEditable = widget.initialIsAmountEditable;
    _isAddressEditable = widget.initialIsAddressEditable;
    _walletName = widget.initialWalletName;
    _selectedCurrency = widget.initialCurrency;
    _isAmountEstimated = widget.isAmountEstimated;
    _isMoneroWallet = widget.isMoneroWallet;
    addressController.text = widget.initialAddress;
    super.initState();
  }

  void changeLimits({String min, String max}) {
    setState(() {
      _min = min;
      _max = max;
    });
  }

  void changeSelectedCurrency(CryptoCurrency currency) {
    setState(() => _selectedCurrency = currency);
  }

  void changeWalletName(String walletName) {
    setState(() => _walletName = walletName);
  }

  void changeIsAction(bool isActive) {
    setState(() => _isAmountEditable = isActive);
  }

  void isAmountEditable({bool isEditable = true}) {
    setState(() => _isAmountEditable = isEditable);
  }

  void isAddressEditable({bool isEditable = true}) {
    setState(() => _isAddressEditable = isEditable);
  }

  void changeAddress({String address}) {
    setState(() => addressController.text = address);
  }

  void changeAmount({String amount}) {
    setState(() => amountController.text = amount);
  }

  void changeIsAmountEstimated(bool isEstimated) {
    setState(() => _isAmountEstimated = isEstimated);
  }

  @override
  Widget build(BuildContext context) {
    final copyImage = Image.asset('assets/images/copy_content.png',
        height: 16,
        width: 16,
        color: Theme.of(context).primaryTextTheme.display2.color);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
          Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              _title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headline.color),
            )
          ],
        ),
        Padding(
            padding: EdgeInsets.only(top: 20),
            child: Stack(
              children: <Widget>[
                BaseTextFormField(
                    focusNode: widget.amountFocusNode,
                    controller: amountController,
                    enabled: _isAmountEditable,
                    textAlign: TextAlign.left,
                    keyboardType: TextInputType.numberWithOptions(
                        signed: false, decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))
                    ],
                    hintText: '0.0000',
                    borderColor: widget.borderColor,
                    textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    placeholderTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .accentTextTheme
                            .display4
                            .decorationColor),
                    validator: _isAmountEditable
                        ? widget.currencyValueValidator
                        : null),
                Positioned(
                  top: 8,
                  right: 0,
                  child: Container(
                    height: 32,
                    padding: EdgeInsets.only(left: 10),
                    color: widget.currencyButtonColor,
                    child: InkWell(
                      onTap: () => _presentPicker(context),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_selectedCurrency.toString(),
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white)),
                            Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: widget.imageArrow,
                            )
                          ]),
                    ),
                  ),
                ),
                if (widget.hasAllAmount)
                  Positioned(
                      top: 5,
                      right: 55,
                      child: Container(
                        height: 32,
                        width: 32,
                        margin: EdgeInsets.only(left: 14, top: 4, bottom: 10),
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .display1
                                .color,
                            borderRadius: BorderRadius.all(Radius.circular(6))),
                        child: InkWell(
                          onTap: () => widget.allAmount?.call(),
                          child: Center(
                            child: Text(S.of(context).all,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .primaryTextTheme
                                        .display1
                                        .decorationColor)),
                          ),
                        ),
                      ))
              ],
            )),
        Padding(
          padding: EdgeInsets.only(top: 5),
          child: Container(
              height: 15,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    _min != null
                        ? Text(
                            S
                                .of(context)
                                .min_value(_min, _selectedCurrency.toString()),
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display4
                                    .decorationColor),
                          )
                        : Offstage(),
                    _min != null ? SizedBox(width: 10) : Offstage(),
                    _max != null
                        ? Text(
                            S
                                .of(context)
                                .max_value(_max, _selectedCurrency.toString()),
                            style: TextStyle(
                                fontSize: 10,
                                height: 1.2,
                                color: Theme.of(context)
                                    .accentTextTheme
                                    .display4
                                    .decorationColor))
                        : Offstage(),
                  ])),
        ),
        !_isAddressEditable && widget.hasRefundAddress
            ? Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  S.of(context).refund_address,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .accentTextTheme
                          .display4
                          .decorationColor),
                ))
            : Offstage(),
        _isAddressEditable
            ? Padding(
                padding: EdgeInsets.only(top: 20),
                child: AddressTextField(
                  focusNode: widget.addressFocusNode,
                  controller: addressController,
                  placeholder: widget.hasRefundAddress
                      ? S.of(context).refund_address
                      : null,
                  options: [
                    AddressTextFieldOption.paste,
                    AddressTextFieldOption.qrCode,
                    AddressTextFieldOption.addressBook,
                  ],
                  isBorderExist: false,
                  textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .accentTextTheme
                          .display4
                          .decorationColor),
                  buttonColor: widget.addressButtonsColor,
                  validator: widget.addressTextFieldValidator,
                  onPushPasteButton: widget.onPushPasteButton,
                ),
              )
            : Padding(
                padding: EdgeInsets.only(top: 10),
                child: Builder(
                    builder: (context) => Stack(
                      children: <Widget> [
                        BaseTextFormField(
                            controller: addressController,
                            readOnly: true,
                            borderColor: Colors.transparent,
                            suffixIcon: SizedBox(
                              width: _isMoneroWallet ? 80 : 36
                            ),
                            textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                            validator: widget.addressTextFieldValidator
                        ),
                        Positioned(
                            top: 2,
                            right: 0,
                            child: SizedBox(
                              width: _isMoneroWallet ? 80 : 36,
                              child: Row(
                                children: <Widget>[
                                  if (_isMoneroWallet) Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Container(
                                        width: 34,
                                        height: 34,
                                        padding: EdgeInsets.only(top: 0),
                                        child: InkWell(
                                          onTap: () async {
                                            final contact = await Navigator
                                              .of(context, rootNavigator: true)
                                              .pushNamed(
                                                Routes.pickerAddressBook);

                                            if (contact is ContactBase &&
                                                contact.address != null) {
                                              setState(() =>
                                              addressController.text =
                                                  contact.address);
                                            }
                                          },
                                          child: Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: widget
                                                    .addressButtonsColor,
                                                borderRadius: BorderRadius
                                                    .all(Radius.circular(6))),
                                              child: Image.asset(
                                                'assets/images/open_book.png',
                                                color: Theme.of(context)
                                                    .primaryTextTheme
                                                    .display1
                                                    .decorationColor,
                                              )),
                                        )),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(left: 2),
                                    child: Container(
                                        width: 34,
                                        height: 34,
                                        padding: EdgeInsets.only(top: 0),
                                        child: InkWell(
                                          onTap: () {
                                            Clipboard.setData(
                                                ClipboardData(
                                                  text: addressController.text));
                                            showBar<void>(
                                                context, S.of(context)
                                                .copied_to_clipboard);
                                          },
                                          child: Container(
                                              padding: EdgeInsets
                                                  .fromLTRB(8, 8, 0, 8),
                                              color: Colors.transparent,
                                              child: copyImage),
                                        ))
                                  )
                                ]
                              )
                            )
                        )
                      ]
                    )
                ),
              ),
      ]),
    );
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
        builder: (_) => CurrencyPicker(
            selectedAtIndex: widget.currencies.indexOf(_selectedCurrency),
            items: widget.currencies,
            title: S.of(context).change_currency,
            onItemSelected: (CryptoCurrency item) =>
                widget.onCurrencySelected != null
                    ? widget.onCurrencySelected(item)
                    : null),
        context: context);
  }
}
