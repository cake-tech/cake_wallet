import 'package:cake_wallet/entities/contact_base.dart';
import 'package:cake_wallet/entities/crypto_currency.dart';

class WalletContact implements ContactBase {
  WalletContact(this.address, this.name, this.type);

  @override
  String address;

  @override
  String name;

  @override
  CryptoCurrency type;
}
