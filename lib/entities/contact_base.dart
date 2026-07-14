import 'package:cw_core/crypto_currency.dart';

abstract class ContactBase {
  ContactBase(this.name, this.address, this.type, {this.displayName = ""});

  String name;

  String address;

  String displayName;

  CryptoCurrency type;
}