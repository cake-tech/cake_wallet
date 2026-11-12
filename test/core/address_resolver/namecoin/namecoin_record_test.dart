import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/namecoin/namecoin_record.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Namecoin identifiers', () {
    test('normalizes d/, id/, and .bit names', () {
      expect(NamecoinRecord.normalizeIdentifier(' D/TestLS '), 'd/testls');
      expect(NamecoinRecord.normalizeIdentifier('id/Alice'), 'id/alice');
      expect(NamecoinRecord.normalizeIdentifier('Alice.bit'), 'd/alice');
      expect(NamecoinRecord.normalizeIdentifier('alice.bit.'), 'd/alice');
      expect(NamecoinRecord.isNamecoinIdentifier('d/alice'), isTrue);
    });

    test('does not capture unrelated providers or malformed names', () {
      for (final value in [
        'example.com',
        'name.eth',
        'user@example.com',
        'bit',
        '.bit',
        'd/',
        'id/',
        'x/alice',
        'd/alice/other',
        'd/alice..bit',
        'd/-alice',
        'd/alice-',
        'd/alice bit',
      ]) {
        expect(NamecoinRecord.normalizeIdentifier(value), isNull, reason: value);
      }
    });
  });

  group('Namecoin payment values', () {
    test('supports every unique Cake currency name, including network variants', () {
      final lowerCaseNames = CryptoCurrency.all.map((item) => item.name.toLowerCase()).toSet();
      expect(lowerCaseNames.length, CryptoCurrency.all.length);

      final value = json.encode({
        for (final currency in CryptoCurrency.all) currency.name: 'address-${currency.name}',
      });

      final addresses = NamecoinRecord.parseAddresses(value);
      expect(addresses.length, CryptoCurrency.all.length);
      for (final currency in CryptoCurrency.all) {
        expect(addresses[currency], 'address-${currency.name}', reason: currency.name);
      }
    });

    test('uses case-insensitive names and object address fields', () {
      final addresses = NamecoinRecord.parseAddresses(
        '{"BTC":"bc1-main","USDTERC20":{"address":"0x1234"},"XMR":{"address":" 4abc "}}',
      );

      expect(addresses, {
        CryptoCurrency.btc: 'bc1-main',
        CryptoCurrency.usdterc20: '0x1234',
        CryptoCurrency.xmr: '4abc',
      });
    });

    test('returns only the requested currencies', () {
      final addresses = NamecoinRecord.parseAddresses(
        '{"btc":"bc1-main","xmr":"4abc"}',
        currencies: const [CryptoCurrency.xmr, CryptoCurrency.doge],
      );

      expect(addresses, {CryptoCurrency.xmr: '4abc'});
    });

    test('ignores unknown currencies and malformed or non-object values', () {
      for (final value in [
        'not json',
        'null',
        '[]',
        '"btc"',
        '42',
        '{"unknown":"address"}',
        '{"btc":null}',
        '{"btc":42}',
        '{"btc":{}}',
        '{"btc":{"address":""}}',
      ]) {
        expect(NamecoinRecord.parseAddresses(value), isEmpty, reason: value);
      }
    });
  });
}
