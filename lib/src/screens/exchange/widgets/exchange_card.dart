import 'package:cake_wallet/core/amount_validator.dart';
import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/src/screens/receive/widgets/currency_input_field.dart';
import 'package:cake_wallet/themes/extensions/qr_code_theme.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/themes/extensions/exchange_page_theme.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';

class ExchangeCard<T extends Currency> extends StatefulWidget {
  ExchangeCard({
    Key? key,
    required this.initialCurrency,
    required this.initialAddress,
    required this.initialWalletName,
    required this.initialIsAmountEditable,
    required this.isAmountEstimated,
    required this.currencies,
    required this.onCurrencySelected,
    this.imageArrow,
    this.currencyValueValidator,
    this.addressTextFieldValidator,
    this.title = '',
    this.initialIsAddressEditable = true,
    this.hasRefundAddress = false,
    this.isMoneroWallet = false,
    this.currencyButtonColor = Colors.transparent,
    this.addressButtonsColor = Colors.transparent,
    this.borderColor = Colors.transparent,
    this.hasAllAmount = false,
    this.isAllAmountEnabled = false,
    this.showAddressField = true,
    this.showLimitsField = true,
    this.amountFocusNode,
    this.addressFocusNode,
    this.allAmount,
    this.currencyRowPadding,
    this.addressRowPadding,
    this.onPushPasteButton,
    this.onPushAddressBookButton,
    this.onDispose,
    required this.cardInstanceName,
  }) : super(key: key);

  final List<T> currencies;
  final Function(T) onCurrencySelected;
  final String title;
  final T initialCurrency;
  final String initialWalletName;
  final String initialAddress;
  final bool initialIsAmountEditable;
  final bool initialIsAddressEditable;
  final bool isAmountEstimated;
  final bool hasRefundAddress;
  final bool isMoneroWallet;
  final Image? imageArrow;
  final Color currencyButtonColor;
  final Color? addressButtonsColor;
  final Color borderColor;
  final FormFieldValidator<String>? currencyValueValidator;
  final FormFieldValidator<String>? addressTextFieldValidator;
  final FormFieldValidator<String> allAmountValidator = AllAmountValidator();
  final FocusNode? amountFocusNode;
  final FocusNode? addressFocusNode;
  final bool hasAllAmount;
  final bool showAddressField;
  final bool showLimitsField;
  final bool isAllAmountEnabled;
  final VoidCallback? allAmount;
  final EdgeInsets? currencyRowPadding;
  final EdgeInsets? addressRowPadding;
  final void Function(BuildContext context)? onPushPasteButton;
  final void Function(BuildContext context)? onPushAddressBookButton;
  final Function()? onDispose;
  final String cardInstanceName;

  @override
  ExchangeCardState<T> createState() => ExchangeCardState<T>();
}

class ExchangeCardState<T extends Currency> extends State<ExchangeCard<T>> {
  ExchangeCardState()
      : _title = '',
        _min = '',
        _max = '',
        _isAmountEditable = false,
        _isAddressEditable = false,
        _walletName = '',
        _isAmountEstimated = false,
        _isMoneroWallet = false,
        _cardInstanceName = '';

  final addressController = TextEditingController();
  final amountController = TextEditingController();

  String _cardInstanceName;
  String _title;
  String? _min;
  String? _max;
  late T _selectedCurrency;
  String _walletName;
  bool _isAmountEditable;
  bool _isAddressEditable;
  bool _isAmountEstimated;
  bool _isMoneroWallet;

  @override
  void initState() {
    _cardInstanceName = widget.cardInstanceName;
    _title = widget.title;
    _isAmountEditable = widget.initialIsAmountEditable;
    _isAddressEditable = widget.initialIsAddressEditable;
    _walletName = widget.initialWalletName;
    _selectedCurrency = widget.initialCurrency;
    _isAmountEstimated = widget.isAmountEstimated;
    _isMoneroWallet = widget.isMoneroWallet;
    addressController.text = _normalizeAddressFormat(widget.initialAddress);

    super.initState();
  }

  @override
  void dispose() {
    widget.onDispose?.call();

    super.dispose();
  }

  void changeLimits({String? min, String? max}) {
    setState(() {
      _min = min;
      _max = max;
    });
  }

  void changeSelectedCurrency(T currency) {
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

  void changeAddress({required String address}) {
    setState(() => addressController.text = _normalizeAddressFormat(address));
  }

  void changeAmount({required String amount}) {
    setState(() => amountController.text = amount);
  }

  void changeIsAmountEstimated(bool isEstimated) {
    setState(() => _isAmountEstimated = isEstimated);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAllAmountEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        amountController.text = S.of(context).all;
      });
    }

    final copyImage = Image.asset('assets/images/copy_content.png',
        height: 16,
        width: 16,
        color: Theme.of(context).extension<SendPageTheme>()!.estimatedFeeColor);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Text(
              key: ValueKey('${_cardInstanceName}_title_key'),
              _title,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).extension<QRCodeTheme>()!.qrCodeColor),
            )
          ],
        ),
        CurrencyAmountTextField(
          currencyPickerButtonKey: ValueKey('${_cardInstanceName}_currency_picker_button_key'),
          selectedCurrencyTextKey: ValueKey('${_cardInstanceName}_selected_currency_text_key'),
          selectedCurrencyTagTextKey:
              ValueKey('${_cardInstanceName}_selected_currency_tag_text_key'),
          amountTextfieldKey: ValueKey('${_cardInstanceName}_amount_textfield_key'),
          sendAllButtonKey: ValueKey('${_cardInstanceName}_send_all_button_key'),
          currencyAmountTextFieldWidgetKey:
              ValueKey('${_cardInstanceName}_currency_amount_textfield_widget_key'),
          imageArrow: widget.imageArrow,
          selectedCurrency: _selectedCurrency.toString(),
          amountFocusNode: widget.amountFocusNode,
          amountController: amountController,
          onTapPicker: () => _presentPicker(context),
          isAmountEditable: _isAmountEditable,
          isPickerEnable: true,
          allAmountButton: widget.hasAllAmount,
          currencyValueValidator: widget.currencyValueValidator,
          tag: _selectedCurrency.tag,
          allAmountCallback: widget.allAmount,
        ),
        Divider(height: 1, color: Theme.of(context).extension<SendPageTheme>()!.textFieldHintColor),
        Padding(
          padding: EdgeInsets.only(top: 5),
          child: widget.showLimitsField ? Container(
              height: 15,
              child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                _min != null
                    ? Text(
                        key: ValueKey('${_cardInstanceName}_min_limit_text_key'),
                        S.of(context).min_value(_min ?? '', _selectedCurrency.toString()),
                        style: TextStyle(
                            fontSize: 10,
                            height: 1.2,
                            color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor),
                      )
                    : Offstage(),
                _min != null ? SizedBox(width: 10) : Offstage(),
                _max != null
                    ? Text(
                        key: ValueKey('${_cardInstanceName}_max_limit_text_key'),
                        S.of(context).max_value(_max ?? '', _selectedCurrency.toString()),
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor,
                        ),
                      )
                    : Offstage(),
              ])) : Offstage(),
        ),
        !_isAddressEditable && widget.hasRefundAddress
            ? Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  S.of(context).refund_address,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor),
                ))
            : Offstage(),
        _isAddressEditable
            ? widget.showAddressField
            ? FocusTraversalOrder(
                order: NumericFocusOrder(2),
                child: Padding(
                  padding: widget.addressRowPadding ?? EdgeInsets.only(top: 20),
                  child: AddressTextField(
                      addressKey: ValueKey('${_cardInstanceName}_editable_address_textfield_key'),
                      focusNode: widget.addressFocusNode,
                      controller: addressController,
                      onURIScanned: (uri) {
                        final paymentRequest = PaymentRequest.fromUri(uri);
                        addressController.text = paymentRequest.address;

                        if (amountController.text.isNotEmpty) {
                          _showAmountPopup(context, paymentRequest);
                          return;
                        }
                        widget.amountFocusNode?.requestFocus();
                        amountController.text = paymentRequest.amount;
                      },
                      placeholder:
                      widget.hasRefundAddress ? S.of(context).refund_address : null,
                      options: [
                        AddressTextFieldOption.paste,
                        AddressTextFieldOption.qrCode,
                        AddressTextFieldOption.addressBook,
                      ],
                      isBorderExist: false,
                      textStyle: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                          Theme.of(context).extension<ExchangePageTheme>()!.hintTextColor),
                      buttonColor: widget.addressButtonsColor,
                      validator: widget.addressTextFieldValidator,
                      onPushPasteButton: widget.onPushPasteButton,
                      onPushAddressBookButton: widget.onPushAddressBookButton,
                      selectedCurrency: _selectedCurrency),
                ),
        )
            : Offstage()
            : Padding(
                padding: EdgeInsets.only(top: 10),
                child: Builder(
                    builder: (context) => Stack(children: <Widget>[
                          FocusTraversalOrder(
                            order: NumericFocusOrder(3),
                            child: BaseTextFormField(
                                key: ValueKey(
                                    '${_cardInstanceName}_non_editable_address_textfield_key'),
                                controller: addressController,
                                borderColor: Colors.transparent,
                                suffixIcon: SizedBox(width: _isMoneroWallet ? 80 : 36),
                                textStyle: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                validator: widget.addressTextFieldValidator),
                          ),
                          Positioned(
                              top: 2,
                              right: 0,
                              child: SizedBox(
                                  width: _isMoneroWallet ? 80 : 36,
                                  child: Row(children: <Widget>[
                                    if (_isMoneroWallet)
                                      Padding(
                                        padding: EdgeInsets.only(left: 10),
                                        child: Container(
                                            width: 34,
                                            height: 34,
                                            padding: EdgeInsets.only(top: 0),
                                            child: Semantics(
                                              label: S.of(context).address_book,
                                              child: InkWell(
                                                key: ValueKey(
                                                    '${_cardInstanceName}_address_book_button_key'),
                                                onTap: () async {
                                                  final contact =
                                                      await Navigator.of(context).pushNamed(
                                                    Routes.pickerAddressBook,
                                                    arguments: widget.initialCurrency,
                                                  );

                                                  if (contact is ContactBase) {
                                                    setState(() =>
                                                        addressController.text = contact.address);
                                                    widget.onPushAddressBookButton?.call(context);
                                                  }
                                                },
                                                child: Container(
                                                    padding: EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                        color: widget.addressButtonsColor,
                                                        borderRadius:
                                                            BorderRadius.all(Radius.circular(6))),
                                                    child: Image.asset(
                                                      'assets/images/open_book.png',
                                                      color: Theme.of(context)
                                                          .extension<SendPageTheme>()!
                                                          .textFieldButtonIconColor,
                                                    )),
                                              ),
                                            )),
                                      ),
                                    Padding(
                                        padding: EdgeInsets.only(left: 2),
                                        child: Container(
                                            width: 34,
                                            height: 34,
                                            padding: EdgeInsets.only(top: 0),
                                            child: Semantics(
                                              label: S.of(context).copy_address,
                                              child: InkWell(
                                                key: ValueKey(
                                                    '${_cardInstanceName}_copy_refund_address_button_key'),
                                                onTap: () {
                                                  Clipboard.setData(
                                                      ClipboardData(text: addressController.text));
                                                  showBar<void>(
                                                      context, S.of(context).copied_to_clipboard);
                                                },
                                                child: Container(
                                                    padding: EdgeInsets.fromLTRB(8, 8, 0, 8),
                                                    color: Colors.transparent,
                                                    child: copyImage),
                                              ),
                                            )))
                                  ])))
                        ])),
              ),
      ]),
    );
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (_) => CurrencyPicker(
        key: ValueKey('${_cardInstanceName}_currency_picker_dialog_button_key'),
        selectedAtIndex: widget.currencies.indexOf(_selectedCurrency),
        items: widget.currencies,
        hintText: S.of(context).search_currency,
        isMoneroWallet: _isMoneroWallet,
        isConvertFrom: widget.hasRefundAddress,
        onItemSelected: (Currency item) => widget.onCurrencySelected(item as T),
      ),
    );
  }

  void _showAmountPopup(BuildContext context, PaymentRequest paymentRequest) {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return AlertWithTwoActions(
              alertTitle: S.of(dialogContext).overwrite_amount,
              alertContent: S.of(dialogContext).qr_payment_amount,
              rightButtonText: S.of(dialogContext).ok,
              leftButtonText: S.of(dialogContext).cancel,
              actionRightButton: () {
                widget.amountFocusNode?.requestFocus();
                amountController.text = paymentRequest.amount;
                Navigator.of(dialogContext).pop();
              },
              actionLeftButton: () => Navigator.of(dialogContext).pop());
        });
  }

  String _normalizeAddressFormat(String address) {
    if (address.startsWith('bitcoincash:')) address = address.substring(12);
    return address;
  }
}

