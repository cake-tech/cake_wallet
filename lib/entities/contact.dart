import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/utils/mobx.dart';
import 'package:cw_core/keyable.dart';

part 'contact.g.dart';

@HiveType(typeId: Contact.typeId)
class Contact extends HiveObject with Keyable {
  Contact({required this.nameRaw, required this.addressRaw, CryptoCurrency? type}) {
    if (type != null) {
      raw = type.raw;
    }
  }

  factory Contact.create({required String name, required String address, CryptoCurrency? type})
    => Contact(
      nameRaw: name,
      addressRaw: address,
      type: type);

  static const typeId = 0;
  static const boxName = 'Contacts';

  @HiveField(0)
  String? nameRaw;

  @HiveField(1)
  String? addressRaw;

  @HiveField(2)
  late int? raw;

  String get name => nameRaw ?? '';

  set name(String value) => name = value;
  
  String get address => addressRaw ?? '';

  set address(String value) => address = value;

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: raw ?? 0);

  @override
  dynamic get keyIndex => key;

  @override
  bool operator ==(Object o) => o is Contact && o.key == key;

  @override
  int get hashCode => key.hashCode;

  void updateCryptoCurrency({required CryptoCurrency currency}) =>
      raw = currency.raw;
}
