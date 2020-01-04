import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';

class ExchangeCard extends StatefulWidget {
  final List<CryptoCurrency> currencies;
  final Function(CryptoCurrency) onCurrencySelected;
  final CryptoCurrency initialCurrency;
  final String initialWalletName;
  final String initialAddress;
  final bool initialIsAmountEditable;
  final bool initialIsAddressEditable;
  final bool isAmountEstimated;
  final Image imageArrow;
  final FormFieldValidator<String> currencyValueValidator;
  final FormFieldValidator<String> addressTextFieldValidator;

  ExchangeCard(
      {Key key,
      this.initialCurrency,
      this.initialAddress,
      this.initialWalletName,
      this.initialIsAmountEditable,
      this.initialIsAddressEditable,
      this.isAmountEstimated,
      this.currencies,
      this.onCurrencySelected,
      this.imageArrow,
      this.currencyValueValidator,
      this.addressTextFieldValidator})
      : super(key: key);

  @override
  createState() => ExchangeCardState();
}

class ExchangeCardState extends State<ExchangeCard> {
  final addressController = TextEditingController();
  final amountController = TextEditingController();

  String _min;
  String _max;
  CryptoCurrency _selectedCurrency;
  String _walletName;
  bool _isAmountEditable;
  bool _isAddressEditable;
  bool _isAmountEstimated;

  @override
  void initState() {
    _isAmountEditable = widget.initialIsAmountEditable;
    _isAddressEditable = widget.initialIsAddressEditable;
    _walletName = widget.initialWalletName;
    _selectedCurrency = widget.initialCurrency;
    _isAmountEstimated = widget.isAmountEstimated;
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

    return Container(
      padding: EdgeInsets.fromLTRB(22, 15, 22, 30),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Column(children: <Widget>[
        _isAmountEstimated != null && _isAmountEstimated
            ? Row(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[
                SizedBox(
                  height: 30,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                    decoration: BoxDecoration(
                        color: Palette.lightGrey,
                        borderRadius: BorderRadius.circular(10.0)),
                    child: Text(
                      S.of(context).estimated,
                      style: TextStyle(
                          fontSize: 14,
                          color: Palette.wildDarkBlue,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ])
            : Container(),
        Container(
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 52,
                  width: 80,
                  child: InkWell(
                    onTap: () => _presentPicker(context),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(_selectedCurrency.toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        color: Theme.of(context).primaryTextTheme.title.color)),
                                widget.imageArrow
                              ]),
                          _walletName != null
                              ? Text(_walletName,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Palette.wildDarkBlue))
                              : SizedBox(),
                        ]),
                  ),
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    children: [
                      TextFormField(
                          style: TextStyle(fontSize: 23, height: 1.21),
                          controller: amountController,
                          enabled: _isAmountEditable,
                          textAlign: TextAlign.right,
                          keyboardType: TextInputType.numberWithOptions(
                              signed: false, decimal: false),
                          inputFormatters: [BlacklistingTextInputFormatter(new RegExp('[\\-|\\ |\\,]'))],
                          decoration: InputDecoration(
                              hintStyle: TextStyle(
                                  color: Theme.of(context).cardTheme.color,
                                  fontSize: 23,
                                  height: 1.21),
                              hintText: '0.00000000',
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Palette.cakeGreen,
                                      width: 2.0)),
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: _isAmountEditable
                                          ? Palette.deepPurple
                                          : Theme.of(context).focusColor,
                                      width: 1.0))),
                        validator: widget.currencyValueValidator),
                      SizedBox(height: 5),
                      SizedBox(
                        height: 15,
                        width: double.infinity,
                        child: Container(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                _min != null
                                    ? Text(
                                        S.of(context).min_value(_min, _selectedCurrency.toString()),
                                        style: TextStyle(
                                            fontSize: 10,
                                            height: 1.2,
                                            color: Theme.of(context).primaryTextTheme.subtitle.color),
                                      )
                                    : SizedBox(),
                                _min != null ? SizedBox(width: 10) : SizedBox(),
                                _max != null
                                    ? Text(
                                        S.of(context).max_value(_max, _selectedCurrency.toString()),
                                        style: TextStyle(
                                            fontSize: 10,
                                            height: 1.2,
                                            color: Theme.of(context).primaryTextTheme.subtitle.color))
                                    : SizedBox(),
                              ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
        ),
        SizedBox(height: 10),
        AddressTextField(
          controller: addressController,
          isActive: _isAddressEditable,
          options: _isAddressEditable
              ? _walletName != null
                  ? [
                      AddressTextFieldOption.qrCode,
                      AddressTextFieldOption.addressBook,
                      AddressTextFieldOption.subaddressList
                    ]
                  : [
                      AddressTextFieldOption.qrCode,
                      AddressTextFieldOption.addressBook,
                    ]
              : [],
          validator: widget.addressTextFieldValidator,
        )
      ]),
    );
  }

  void _presentPicker(BuildContext context) {
    showDialog(
        builder: (_) => Picker(
            items: widget.currencies,
            selectedAtIndex: widget.currencies.indexOf(_selectedCurrency),
            title: S.of(context).change_currency,
            onItemSelected: (item) => widget.onCurrencySelected != null
                ? widget.onCurrencySelected(item)
                : null),
        context: context);
  }
}
