import 'package:cw_core/crypto_currency.dart';

abstract class ContactBase {
  ContactBase(this.name, this.address, this.type);

  String name;

  String address;

  CryptoCurrency type;
}