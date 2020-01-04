import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';

part 'contact.g.dart';

@HiveType()
class Contact extends HiveObject {
  static const boxName = 'Contacts';

  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
  int raw;

  CryptoCurrency get type => CryptoCurrency.deserialize(raw: raw);

  Contact(
      {@required this.name,
      @required this.address,
      CryptoCurrency type})
      : raw = type?.raw;

  updateCryptoCurrency({@required CryptoCurrency currency}) =>
      raw = currency.raw;
}
