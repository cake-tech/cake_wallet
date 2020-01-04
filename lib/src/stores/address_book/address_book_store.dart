import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/domain/common/contact.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:hive/hive.dart';

part 'address_book_store.g.dart';

class AddressBookStore = AddressBookStoreBase with _$AddressBookStore;

abstract class AddressBookStoreBase with Store {
  @observable
  List<Contact> contactList;

  @observable
  bool isValid;

  @observable
  String errorMessage;

  Box<Contact> contacts;

  AddressBookStoreBase({@required this.contacts}) {
    updateContactList();
  }

  @action
  Future add({Contact contact}) async => contacts.add(contact);

  @action
  Future updateContactList() async => contactList = contacts.values.toList();

  @action
  Future update({Contact contact}) async => contact.save();

  @action
  Future delete({Contact contact}) async => await contact.delete();

  void validateContactName(String value) {
    String p = '''^[^`,'"]{1,32}\$''';
    RegExp regExp = new RegExp(p);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_contact_name;
  }

  void validateAddress(String value, {CryptoCurrency cryptoCurrency}) {
    // XMR (95), BTC (34), ETH (42), LTC (34), BCH (42), DASH (34)
    String p = '^[0-9a-zA-Z]{95}\$|^[0-9a-zA-Z]{34}\$|^[0-9a-zA-Z]{42}\$';
    RegExp regExp = new RegExp(p);
    isValid = regExp.hasMatch(value);
    if (isValid && cryptoCurrency != null) {
      switch (cryptoCurrency.toString()) {
        case 'XMR':
          isValid = (value.length == 95);
          break;
        case 'BTC':
          isValid = (value.length == 34);
          break;
        case 'ETH':
          isValid = (value.length == 42);
          break;
        case 'LTC':
          isValid = (value.length == 34);
          break;
        case 'BCH':
          isValid = (value.length == 42);
          break;
        case 'DASH':
          isValid = (value.length == 34);
      }
    }
    errorMessage = isValid ? null : S.current.error_text_address;
  }
}
