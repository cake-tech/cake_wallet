import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/themes/extensions/transaction_trade_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/core/contact_name_validator.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/view_model/contact_list/contact_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/themes/extensions/address_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';

class ContactPage extends BasePage {
  ContactPage(this.contactViewModel)
      : _formKey = GlobalKey<FormState>(),
        _nameController = TextEditingController(),
        _addressController = TextEditingController(),
        _currencyTypeController = TextEditingController() {
    _nameController.text = contactViewModel.name;
    _addressController.text = contactViewModel.address;
    _nameController
        .addListener(() => contactViewModel.name = _nameController.text);
    _addressController
        .addListener(() => contactViewModel.address = _addressController.text);

    autorun((_) => _currencyTypeController.text =
        contactViewModel.currency?.toString() ?? '');
  }

  @override
  String get title => S.current.contact;

  final ContactViewModel contactViewModel;
  final GlobalKey<FormState> _formKey;
  final TextEditingController _nameController;
  final TextEditingController _currencyTypeController;
  final TextEditingController _addressController;

  @override
  Widget body(BuildContext context) {
    final downArrow = Image.asset('assets/images/arrow_bottom_purple_icon.png',
        color: Theme.of(context).extension<TransactionTradeTheme>()!.detailsTitlesColor,
        height: 8);

    reaction((_) => contactViewModel.state, (ExecutionState state) {
      if (state is FailureState) {
        _onContactSavingFailure(context, state.error);
      }

      if (state is ExecutedSuccessfullyState) {
        _onContactSavedSuccessfully(context);
      }
    });

    return Observer(
      builder: (_) => ScrollableWithBottomSection(
          contentPadding: EdgeInsets.all(24),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BaseTextFormField(
                    controller: _nameController,
                    hintText: S.of(context).contact_name,
                    validator: ContactNameValidator()),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Container(
                    child: InkWell(
                      onTap: () => _presentCurrencyPicker(context),
                      child: IgnorePointer(
                          child: BaseTextFormField(
                        controller: _currencyTypeController,
                        hintText: S.of(context).settings_currency,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[downArrow],
                        ),
                      )),
                    ),
                  ),
                ),
                if (contactViewModel.currency != null)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: AddressTextField(
                      controller: _addressController,
                      options: [
                        AddressTextFieldOption.paste,
                        AddressTextFieldOption.qrCode,
                      ],
                      buttonColor: Theme.of(context).extension<AddressTheme>()!.actionButtonColor,
                      iconColor: PaletteDark.gray,
                      borderColor: Theme.of(context).extension<CakeTextTheme>()!.textfieldUnderlineColor,
                      validator:
                          AddressValidator(type: contactViewModel.currency!),
                    ),
                  )
              ],
            ),
          ),
          bottomSectionPadding:
              EdgeInsets.only(left: 24, right: 24, bottom: 24),
          bottomSection: Row(
            children: <Widget>[
              Expanded(
                child: PrimaryButton(
                    onPressed: () {
                      contactViewModel.reset();
                      _nameController.text = '';
                      _addressController.text = '';
                    },
                    text: S.of(context).reset,
                    color: Colors.orange,
                    textColor: Colors.white),
              ),
              SizedBox(width: 20),
              Expanded(
                  child: Observer(
                      builder: (_) => PrimaryButton(
                          onPressed: () async {
                            if (_formKey.currentState != null &&
                                !_formKey.currentState!.validate()) {
                              return;
                            }

                            await contactViewModel.save();
                          },
                          text: S.of(context).save,
                          color: Theme.of(context).primaryColor,
                          textColor: Colors.white,
                          isDisabled: !contactViewModel.isReady)))
            ],
          )),
    );
  }

  void _presentCurrencyPicker(BuildContext context) {
    showPopUp<void>(
        builder: (_) => CurrencyPicker(
            selectedAtIndex: contactViewModel.currency != null
                ? contactViewModel.currencies
                    .indexOf(contactViewModel.currency!)
                : -1,
            items: contactViewModel.currencies,
            title: S.of(context).please_select,
            hintText: S.of(context).search_currency,
            onItemSelected: (Currency item) =>
                contactViewModel.currency = item as CryptoCurrency),
        context: context);
  }

  void _onContactSavingFailure(BuildContext context, String error) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.current.contact,
              alertContent: error,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  void _onContactSavedSuccessfully(BuildContext context) =>
      Navigator.of(context).pop();
}
