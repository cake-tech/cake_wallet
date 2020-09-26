import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/contact.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';
import 'package:cake_wallet/entities/record.dart';

part 'contact_record.g.dart';

class ContactRecord = ContactRecordBase with _$ContactRecord;

abstract class ContactRecordBase extends Record<Contact> with Store {
  ContactRecordBase(Box<Contact> source, Contact original)
      : super(source, original);

  @observable
  String name;

  @observable
  String address;

  @observable
  CryptoCurrency type;

  @override
  void toBind(Contact original) {
    reaction((_) => name, (String name) => original.name = name);
    reaction((_) => address, (String address) => original.address = address);
    reaction(
        (_) => type,
        (CryptoCurrency currency) =>
            original.updateCryptoCurrency(currency: currency));
  }

  @override
  void fromBind(Contact original) {
    name = original.name;
    address = original.address;
    type = original.type;
  }
}
