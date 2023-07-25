import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_core/keyable.dart';
import 'package:hive/hive.dart';

part 'contact.g.dart';

@HiveType(typeId: Contact.typeId)
class Contact extends HiveObject with Keyable {
  Contact({required this.name, required this.address, CryptoCurrency? type}) {
    if (type != null) {
      raw = type.raw;
    }
  }

  static const typeId = CONTACT_TYPE_ID;
  static const boxName = 'Contacts';

  @HiveField(0, defaultValue: '')
  String name;

  @HiveField(1, defaultValue: '')
  String address;

  @HiveField(2, defaultValue: 0)
  late int raw;

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: raw);

  @override
  dynamic get keyIndex => key;

  @override
  bool operator ==(Object o) => o is Contact && o.key == key;

  @override
  int get hashCode => key.hashCode;

  void updateCryptoCurrency({required CryptoCurrency currency}) =>
      raw = currency.raw;
}
