import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/keyable.dart';

part 'contact.g.dart';

@HiveType(typeId: Contact.typeId)
class Contact extends HiveObject with Keyable {
  Contact({required this.name, required this.address, CryptoCurrency? type}) {
    if (type != null) {
      raw = type.raw;
    }
  }

  static const typeId = 0;
  static const boxName = 'Contacts';

  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
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
