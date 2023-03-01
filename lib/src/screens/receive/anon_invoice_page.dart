import 'package:cake_wallet/entities/receive_page_option.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/dashboard/widgets/present_fee_picker.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/utils/debounce.dart';
import 'package:cake_wallet/view_model/anon_invoice_page_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/address_page_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/keyboard_done_button.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/exchange_card.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:mobx/mobx.dart';

class AnonPayInvoicePage extends BasePage {
  AnonPayInvoicePage(this.anonInvoicePageViewModel, this.addressPageViewModel) {
    addressPageViewModel.selectReceiveOption(ReceivePageOption.anonPayInvoice);
  }

  final AnonInvoicePageViewModel anonInvoicePageViewModel;
  final AddressPageViewModel addressPageViewModel;
  final depositKey = GlobalKey<ExchangeCardState>();
  final receiveKey = GlobalKey<ExchangeCardState>();
  final _formKey = GlobalKey<FormState>();
  final _depositAmountFocus = FocusNode();
  final _depositAddressFocus = FocusNode();
  final _receiveAmountFocus = FocusNode();
  final _receiveAddressFocus = FocusNode();
  final _receiveAmountDebounce = Debounce(Duration(milliseconds: 500));
  final _depositAmountDebounce = Debounce(Duration(milliseconds: 500));
  bool effectsInstalled = false;
  @override
  Color get titleColor => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => false;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget middle(BuildContext context) =>
      PresentFeePicker(addressPageViewModel: addressPageViewModel);

  @override
  Widget trailing(BuildContext context) => TrailButton(
      caption: S.of(context).clear,
      onPressed: () {
        _formKey.currentState?.reset();
        anonInvoicePageViewModel.reset();
      });
  final _amountController = TextEditingController();

  final _addressController = TextEditingController();

  @override
  Widget body(BuildContext context) {
    final arrowBottomPurple = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: Colors.white,
      height: 8,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context));

    // final depositWalletName = exchangeViewModel.depositCurrency == CryptoCurrency.xmr
    //     ? exchangeViewModel.wallet.name
    //     : null;
    // final receiveWalletName = exchangeViewModel.receiveCurrency == CryptoCurrency.xmr
    //     ? exchangeViewModel.wallet.name
    //     : null;

    // WidgetsBinding.instance.addPostFrameCallback((_) => _setReactions(context, exchangeViewModel));

    // if (exchangeViewModel.isLowFee) {
    //   _showFeeAlert(context);
    // }

    return KeyboardActions(
      disableScroll: true,
      config: KeyboardActionsConfig(
          keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
          keyboardBarColor: Theme.of(context).accentTextTheme.bodyText1!.backgroundColor!,
          nextFocus: false,
          actions: [
            KeyboardActionsItem(
                focusNode: _depositAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()]),
            KeyboardActionsItem(
                focusNode: _receiveAmountFocus, toolbarButtons: [(_) => KeyboardDoneButton()])
          ]),
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Form(
          key: _formKey,
          child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryTextTheme.subtitle2!.color!,
                    Theme.of(context).primaryTextTheme.subtitle2!.decorationColor!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 100, 24, 0),
                child: Column(
                  children: <Widget>[
                    Container(
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color:
                                      Theme.of(context).accentTextTheme.headline6!.backgroundColor!,
                                  width: 1)),
                        ),
                        child: Observer(builder: (_) {
                          final selectedCurrency = anonInvoicePageViewModel.selectedCurrency;

                          return Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.only(right: 8),
                                  height: 32,
                                  child: InkWell(
                                    onTap: () => _presentPicker(context),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.only(right: 5),
                                            child: arrowBottomPurple,
                                          ),
                                          Text(selectedCurrency.name.toUpperCase(),
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Colors.white))
                                        ]),
                                  ),
                                ),
                                selectedCurrency.tag != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(right: 3.0),
                                        child: Container(
                                          height: 32,
                                          decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryTextTheme
                                                  .headline4!
                                                  .color!,
                                              borderRadius: BorderRadius.all(Radius.circular(6))),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(6.0),
                                              child: Text(
                                                selectedCurrency.tag!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .primaryTextTheme
                                                      .headline4!
                                                      .decorationColor!,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Text(':',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.white)),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: BaseTextFormField(
                                          focusNode: _depositAddressFocus,
                                          controller: _amountController,
                                          enabled: true,
                                          textAlign: TextAlign.left,
                                          keyboardType: TextInputType.numberWithOptions(
                                              signed: false, decimal: true),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(RegExp('[\\-|\\ ]'))
                                          ],
                                          hintText: '0.0000',
                                          borderColor: Colors.transparent,
                                          //widget.borderColor,
                                          textStyle: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white),
                                          placeholderTextStyle: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .accentTextTheme
                                                .headline1!
                                                .decorationColor!,
                                          ),
                                          validator: null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })),
                    SizedBox(
                      height: 24,
                    ),
                    BaseTextFormField(
                      controller: _addressController,
                      borderColor: Theme.of(context).accentTextTheme.headline6!.backgroundColor,
                      suffixIcon: SizedBox(width: 36),
                      hintText: 'Optional recipient name',
                      placeholderTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).accentTextTheme.headline1!.decorationColor!,
                      ),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      validator: null,
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    BaseTextFormField(
                      controller: _addressController,
                      borderColor: Theme.of(context).accentTextTheme.headline6!.backgroundColor,
                      suffixIcon: SizedBox(width: 36),
                      hintText: 'Optional description',
                      placeholderTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).accentTextTheme.headline1!.decorationColor!,
                      ),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      validator: null,
                    ),
                    SizedBox(height: 24),
                    BaseTextFormField(
                      controller: _addressController,
                      borderColor: Theme.of(context).accentTextTheme.headline6!.backgroundColor,
                      suffixIcon: SizedBox(width: 36),
                      hintText: 'Optional payee notification email',
                      placeholderTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).accentTextTheme.headline1!.decorationColor!,
                      ),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      validator: null,
                    ),
                    SizedBox(
                      height: 52,
                    ),
                  ],
                ),
              ),
            ),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Observer(builder: (_) {
                    return Center(
                      child: Text(
                        'Generate an invoice. The recipient can pay with any supported cryptocurrency, and you will receive funds in this wallet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).primaryTextTheme.headline1!.decorationColor!,
                            fontWeight: FontWeight.w500,
                            fontSize: 12),
                      ),
                    );
                  }),
                ),
                Observer(
                  builder: (_) => LoadingPrimaryButton(
                    text: 'Create invoice',
                    onPressed: () {
                      if (_formKey.currentState != null && _formKey.currentState!.validate()) {}
                    },
                    color: Theme.of(context).accentTextTheme.bodyText1!.color!,
                    textColor: Colors.white,
                    isDisabled: false,
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setReactions(BuildContext context) {
    if (effectsInstalled) {
      return;
    }

    reaction((_) => addressPageViewModel.selectedReceiveOption, (ReceivePageOption option) {
      Navigator.pop(context);
      switch (option) {
        case ReceivePageOption.mainnet:
          Navigator.popAndPushNamed(context, Routes.addressPage);
          break;
        case ReceivePageOption.anonPayDonationLink:
          Navigator.pop(context);
          break;
        default:
      }
    });

    effectsInstalled = true;
  }

  void _presentPicker(BuildContext context) {
    showPopUp<void>(
      builder: (_) => CurrencyPicker(
        selectedAtIndex: anonInvoicePageViewModel.selectedCurrencyIndex,
        items: anonInvoicePageViewModel.currencies,
        hintText: S.of(context).search_currency,
        isMoneroWallet: false,
        isConvertFrom: false,
        onItemSelected: anonInvoicePageViewModel.selectCurrency,
      ),
      context: context,
    );
  }
}
