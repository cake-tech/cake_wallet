import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';
import 'package:cake_wallet/src/stores/address_book/address_book_store.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/screens/exchange/widgets/currency_picker.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';

class ContactPage extends BasePage {
  ContactPage({this.contact});

  final Contact contact;

  @override
  String get title => S.current.contact;

  @override
  Color get backgroundColor => PaletteDark.historyPanel;

  @override
  Widget body(BuildContext context) => ContactForm(contact);
}

class ContactForm extends StatefulWidget {
  ContactForm(this.contact);

  final Contact contact;

  @override
  State<ContactForm> createState() => ContactFormState();
}

class ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _contactNameController = TextEditingController();
  final _currencyTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final currencies = CryptoCurrency.all;
  final downArrow = Image.asset(
      'assets/images/arrow_bottom_purple_icon.png',
      color: PaletteDark.walletCardText,
      height: 8);

  CryptoCurrency _selectectCrypto;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _selectectCrypto = widget.contact.type;
      _contactNameController.text = widget.contact.name;
      _currencyTypeController.text = _selectectCrypto.toString();
      _addressController.text = widget.contact.address;
      WidgetsBinding.instance.addPostFrameCallback(afterLayout);
    }
  }

  void afterLayout(dynamic _) {
    final addressBookStore = Provider.of<AddressBookStore>(context);
    addressBookStore.setDisabledStatus(false);
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _currencyTypeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void onHandleControllers(AddressBookStore addressBookStore) {
    if (_contactNameController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _currencyTypeController.text.isNotEmpty) {
      addressBookStore.setDisabledStatus(false);
    } else {
      addressBookStore.setDisabledStatus(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressBookStore = Provider.of<AddressBookStore>(context);

    _contactNameController.addListener(() {onHandleControllers(addressBookStore);});
    _currencyTypeController.addListener(() {onHandleControllers(addressBookStore);});
    _addressController.addListener(() {onHandleControllers(addressBookStore);});

    return Container(
      color: PaletteDark.historyPanel,
      child: ScrollableWithBottomSection(
          contentPadding: EdgeInsets.all(24),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BaseTextFormField(
                  controller: _contactNameController,
                  hintText: S.of(context).contact_name,
                  borderColor: PaletteDark.walletCardSubAddressField,
                  validator: (value) {
                    addressBookStore.validateContactName(value);
                    return addressBookStore.errorMessage;
                  }
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Container(
                    child: InkWell(
                      onTap: () => _presentPicker(context),
                      child: IgnorePointer(
                        child: BaseTextFormField(
                          controller: _currencyTypeController,
                          hintText: S.of(context).settings_currency,
                          borderColor: PaletteDark.walletCardSubAddressField,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              downArrow
                            ],
                          ),
                        )
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: AddressTextField(
                    controller: _addressController,
                    options: [AddressTextFieldOption.qrCode],
                    validator: (value) {
                      addressBookStore.validateAddress(value,
                          cryptoCurrency: _selectectCrypto);
                      return addressBookStore.errorMessage;
                    },
                  ),
                )
              ],
            ),
          ),
          bottomSectionPadding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24
          ),
          bottomSection: Row(
            children: <Widget>[
              Expanded(
                child: PrimaryButton(
                    onPressed: () {
                      setState(() {
                        _selectectCrypto = null;
                        _contactNameController.text = '';
                        _currencyTypeController.text = '';
                        _addressController.text = '';
                      });
                    },
                    text: S.of(context).reset,
                    color: Colors.red,
                    textColor: Colors.white
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                  child: Observer(
                    builder: (_) => PrimaryButton(
                      onPressed: () async {
                        if (!_formKey.currentState.validate()) {
                          return;
                        }

                        try {
                          if (widget.contact == null) {
                            final newContact = Contact(
                                name: _contactNameController.text,
                                address: _addressController.text,
                                type: _selectectCrypto);

                            await addressBookStore.add(contact: newContact);
                          } else {
                            widget.contact.name = _contactNameController.text;
                            widget.contact.address = _addressController.text;
                            widget.contact
                                .updateCryptoCurrency(currency: _selectectCrypto);

                            await addressBookStore.update(
                                contact: widget.contact);
                          }
                          Navigator.pop(context);
                        } catch (e) {
                          await showDialog<void>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertWithOneAction(
                                  alertTitle: S.current.contact,
                                  alertContent: e.toString(),
                                  buttonText: S.of(context).ok,
                                  buttonAction: () => Navigator.of(context).pop()
                                );
                              });
                        }
                      },
                      text: S.of(context).save,
                      color: Colors.green,
                      textColor: Colors.white,
                      isDisabled: addressBookStore.isDisabledStatus,
                    )
                  )
              )
            ],
          )),
    );
  }

  void _presentPicker(BuildContext context) {
    showDialog<void>(
        builder: (_) => CurrencyPicker(
            selectedAtIndex: currencies.indexOf(_selectectCrypto),
            items: currencies,
            title: S.of(context).please_select,
            onItemSelected: (CryptoCurrency item) {
              _selectectCrypto = item;
              _currencyTypeController.text = _selectectCrypto.toString();
            }
        ),
        context: context);
  }
}
