import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

class ContactPage extends BasePage {
  String get title => S.current.contact;
  final Contact contact;

  ContactPage({this.contact});

  @override
  Widget body(BuildContext context) => ContactForm(contact);
}

class ContactForm extends StatefulWidget {
  final Contact contact;

  ContactForm(this.contact);

  @override
  createState() => ContactFormState();
}

class ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _contactNameController = TextEditingController();
  final _currencyTypeController = TextEditingController();
  final _addressController = TextEditingController();

  CryptoCurrency _selectectCrypto = CryptoCurrency.xmr;

  @override
  void initState() {
    super.initState();
    if (widget.contact == null) {
      _currencyTypeController.text = _selectectCrypto.toString();
    } else {
      _selectectCrypto = widget.contact.type;
      _contactNameController.text = widget.contact.name;
      _currencyTypeController.text = _selectectCrypto.toString();
      _addressController.text = widget.contact.address;
    }
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _currencyTypeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  _setCurrencyType(BuildContext context) async {
    String currencyType = CryptoCurrency.all[0].toString();
    CryptoCurrency selectedCurrency = CryptoCurrency.all[0];
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).please_select),
            backgroundColor: Theme.of(context).backgroundColor,
            content: Container(
              height: 150.0,
              child: CupertinoPicker(
                  backgroundColor: Theme.of(context).backgroundColor,
                  itemExtent: 45.0,
                  onSelectedItemChanged: (int index) {
                    selectedCurrency = CryptoCurrency.all[index];
                    currencyType = CryptoCurrency.all[index].toString();
                  },
                  children:
                      List.generate(CryptoCurrency.all.length, (int index) {
                    return Center(
                      child: Text(
                        CryptoCurrency.all[index].toString(),
                        style: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .color),
                      ),
                    );
                  })),
            ),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(S.of(context).cancel)),
              FlatButton(
                  onPressed: () {
                    _selectectCrypto = selectedCurrency;
                    _currencyTypeController.text = currencyType;
                    Navigator.of(context).pop();
                  },
                  child: Text(S.of(context).ok))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final addressBookStore = Provider.of<AddressBookStore>(context);

    return ScrollableWithBottomSection(
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                style: TextStyle(
                    fontSize: 14.0,
                    color: Theme.of(context).primaryTextTheme.headline.color),
                decoration: InputDecoration(
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    hintText: S.of(context).contact_name,
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Palette.cakeGreen, width: 2.0)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).focusColor, width: 1.0))),
                controller: _contactNameController,
                validator: (value) {
                  addressBookStore.validateContactName(value);
                  return addressBookStore.errorMessage;
                },
              ),
              SizedBox(height: 14.0),
              Container(
                child: InkWell(
                  onTap: () => _setCurrencyType(context),
                  child: IgnorePointer(
                    child: TextFormField(
                      style: TextStyle(
                          fontSize: 14.0,
                          color: Theme.of(context)
                              .primaryTextTheme
                              .headline
                              .color),
                      decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Palette.cakeGreen,
                                  width: 2.0)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Theme.of(context).focusColor,
                                  width: 1.0))),
                      controller: _currencyTypeController,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 14.0),
              AddressTextField(
                controller: _addressController,
                options: [AddressTextFieldOption.qrCode],
                validator: (value) {
                  addressBookStore.validateAddress(value,
                      cryptoCurrency: _selectectCrypto);
                  return addressBookStore.errorMessage;
                },
              )
            ],
          ),
        ),
        bottomSection: Row(
          children: <Widget>[
            Expanded(
              child: PrimaryButton(
                  onPressed: () {
                    setState(() {
                      _selectectCrypto = CryptoCurrency.xmr;
                      _contactNameController.text = '';
                      _currencyTypeController.text =
                          _selectectCrypto.toString();
                      _addressController.text = '';
                    });
                  },
                  text: S.of(context).reset,
                  color:
                      Theme.of(context).accentTextTheme.button.backgroundColor,
                  borderColor:
                      Theme.of(context).accentTextTheme.button.decorationColor),
            ),
            SizedBox(width: 20),
            Expanded(
                child: PrimaryButton(
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
                          widget.contact.updateCryptoCurrency(currency: _selectectCrypto);

                          await addressBookStore.update(contact: widget.contact);
                        }
                        Navigator.pop(context);
                      } catch (e) {
                        await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  e.toString(),
                                  textAlign: TextAlign.center,
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: Text(S.of(context).ok))
                                ],
                              );
                            });
                      }
                    },
                    text: S.of(context).save,
                    color: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .backgroundColor,
                    borderColor: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .decorationColor))
          ],
        ));
  }
}
