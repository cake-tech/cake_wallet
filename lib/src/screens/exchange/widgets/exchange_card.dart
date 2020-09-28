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
      this.currencies,
      this.onCurrencySelected,
      this.imageArrow,
      this.currencyButtonColor = Colors.transparent,
      this.addressButtonsColor = Colors.transparent,
      this.borderColor = Colors.transparent,
      this.currencyValueValidator,
      this.addressTextFieldValidator})
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
  final Image imageArrow;
  final Color currencyButtonColor;
  final Color addressButtonsColor;
  final Color borderColor;
  final FormFieldValidator<String> currencyValueValidator;
  final FormFieldValidator<String> addressTextFieldValidator;

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

  @override
  void initState() {
    _title = widget.title;
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
    final copyImage = Image.asset('assets/images/copy_content.png',
        height: 16, width: 16,
        color: Theme.of(context).primaryTextTheme.display2.color);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              _title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.headline.color
              ),
            )
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 20),
          child: Stack(
            children: <Widget>[
              BaseTextFormField(
                  controller: amountController,
                  enabled: _isAmountEditable,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.numberWithOptions(
                      signed: false, decimal: true),
                  // inputFormatters: [
                  //   LengthLimitingTextInputFormatter(15),
                  //   BlacklistingTextInputFormatter(
                  //       RegExp('[\\-|\\ |\\,]'))
                  // ],
                  hintText: '0.0000',
                  borderColor: widget.borderColor,
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white
                  ),
                  placeholderTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.subhead.decorationColor
                  ),
                  validator: _isAmountEditable
                             ? widget.currencyValueValidator
                             : null
              ),
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
                          Text(
                              _selectedCurrency.toString(),
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
              )
            ],
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 5),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _min != null
                ? Text(
                  S.of(context).min_value(
                      _min, _selectedCurrency.toString()),
                  style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: Theme.of(context).textTheme.subhead.decorationColor),
                )
                : Offstage(),
                _min != null ? SizedBox(width: 10) : Offstage(),
                _max != null
                ? Text(
                    S.of(context).max_value(
                        _max, _selectedCurrency.toString()),
                    style: TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: Theme.of(context).textTheme.subhead.decorationColor))
                : Offstage(),
              ]),
        ),
        _isAddressEditable
        ? Offstage()
        : Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            S.of(context).refund_address,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.subhead.decorationColor
            ),
          )
        ),
        _isAddressEditable
        ? Padding(
          padding: EdgeInsets.only(top: 20),
          child: AddressTextField(
            controller: addressController,
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
                color: Theme.of(context).textTheme.subhead.decorationColor),
            buttonColor: widget.addressButtonsColor,
            validator: widget.addressTextFieldValidator,
          ),
        )
        : Padding(
          padding: EdgeInsets.only(top: 10),
          child: Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: addressController.text));
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text(
                      S.of(context).copied_to_clipboard,
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 500),
                  ));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        addressController.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: copyImage,
                    )
                  ],
                ),
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
