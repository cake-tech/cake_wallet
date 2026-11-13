import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('THB and TWD use the correct full names and country flags', () {
    expect(FiatCurrency.thb.symbol, 'THB');
    expect(FiatCurrency.thb.fullName, 'Thai Baht');
    expect(FiatCurrency.thb.countryCode, 'tha');

    expect(FiatCurrency.twd.symbol, 'TWD');
    expect(FiatCurrency.twd.fullName, 'New Taiwan Dollar');
    expect(FiatCurrency.twd.countryCode, 'twn');
  });
}
