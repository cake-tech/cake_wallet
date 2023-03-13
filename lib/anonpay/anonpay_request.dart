import 'package:cw_core/crypto_currency.dart';

class AnonPayRequest {
  CryptoCurrency cryptoCurrency;
  String address;
  String name;
  String? amount;
  String email;
  String description;
  String? fiatEquivalent;

  AnonPayRequest({
    required this.cryptoCurrency,
    required this.address,
    required this.name,
    required this.email,
    this.amount,
    required this.description,
    this.fiatEquivalent,
  });
}
