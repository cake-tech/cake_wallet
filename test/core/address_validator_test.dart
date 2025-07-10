import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressValidator', () {
    setUpAll(() {
      S.current = S();
    });
    group('getPattern', () {
      test('returns correct pattern for Bitcoin', () {
        final pattern = AddressValidator.getPattern(CryptoCurrency.btc);
        expect(pattern, isNotEmpty);
        expect(pattern, contains('(bc|tb)1q'));
      });

      test('returns correct pattern for Ethereum', () {
        final pattern = AddressValidator.getPattern(CryptoCurrency.eth);
        expect(pattern, isNotEmpty);
        expect(pattern, contains('0x[0-9a-zA-Z]+'));
      });

      test('returns correct pattern for Monero', () {
        final pattern = AddressValidator.getPattern(CryptoCurrency.xmr);
        expect(pattern, isNotEmpty);
        expect(pattern, contains('4[0-9a-zA-Z]{94}|8[0-9a-zA-Z]{94}|[0-9a-zA-Z]{106}'));
      });

      test('returns correct pattern for Litecoin', () {
        final pattern = AddressValidator.getPattern(CryptoCurrency.ltc);
        expect(pattern, isNotEmpty);
        expect(pattern,
            contains('(bc|tb|ltc)1q[ac-hj-np-z02-9]{25,39}|(ltc|t)mweb1q[ac-hj-np-z02-9]{90,120}'));
      });

      test('returns empty string for unknown currency', () {
        final pattern = AddressValidator.getPattern(CryptoCurrency.btcln);
        expect(pattern, isNotEmpty);
      });
    });

    group('getLength', () {
      test('returns correct length for Bitcoin', () {
        final length = AddressValidator.getLength(CryptoCurrency.btc);
        expect(length, isNull);
      });

      test('returns correct length for Ethereum', () {
        final length = AddressValidator.getLength(CryptoCurrency.eth);
        expect(length, equals([42]));
      });

      test('returns correct length for Monero', () {
        final length = AddressValidator.getLength(CryptoCurrency.xmr);
        expect(length, isNull);
      });

      test('returns correct length for Dash', () {
        final length = AddressValidator.getLength(CryptoCurrency.dash);
        expect(length, equals([34]));
      });
    });

    group('getAddressFromStringPattern', () {
      test('returns correct pattern for Bitcoin', () {
        final pattern = AddressValidator.getAddressFromStringPattern(CryptoCurrency.btc);
        expect(pattern, isNotNull);
        expect(pattern, contains('(bc|tb)1q'));
      });

      test('returns correct pattern for Ethereum', () {
        final pattern = AddressValidator.getAddressFromStringPattern(CryptoCurrency.eth);
        expect(pattern, isNotNull);
        expect(pattern, contains('0x[0-9a-zA-Z]+'));
      });

      test('returns correct pattern for Monero', () {
        final pattern = AddressValidator.getAddressFromStringPattern(CryptoCurrency.xmr);
        expect(pattern, isNotNull);
        expect(pattern, contains('(4[0-9a-zA-Z]{94})'));
      });

      test('returns null for unsupported currency', () {
        final pattern = AddressValidator.getAddressFromStringPattern(CryptoCurrency.dash);
        expect(pattern, isNull);
      });
    });
    // 0.000058158099999999995 BTC
    group('validation', () {
      test('validates valid Bitcoin address', () {
        final validator = AddressValidator(type: CryptoCurrency.btc);
        expect(validator.isValid('bc1qhg4l43pmq5v5atmtlr7gnwyuxs043cvrut5hkq'), isTrue);
        expect(validator.isValid('3AD1Btx1MzYGmdpNpeujCfuvU5SsU2LX88'), isTrue);
        expect(validator.isValid('1HARAhFcvz8ZQp5MhnLFeUynC4bkha3Hv8'), isTrue);
      });

      test('rejects invalid Bitcoin address', () {
        final validator = AddressValidator(type: CryptoCurrency.btc);
        expect(validator.isValid('invalid_address'), isFalse);
        expect(validator.isValid('bc1qhg4l43pmq5v5atmtlr7gnwyuxs043CakeWallet'), isFalse);
      });

      test('validates valid Ethereum address', () {
        final validator = AddressValidator(type: CryptoCurrency.eth);
        expect(validator.isValid('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'),
            isTrue); // WETH contract
      });

      test('rejects invalid Ethereum address', () {
        final validator = AddressValidator(type: CryptoCurrency.eth);
        expect(validator.isValid('invalid_address'), isFalse);
        expect(
            validator.isValid('0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc'), isFalse); // Too short
        expect(validator.isValid('C02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'),
            isFalse); // Missing 0x prefix
      });

      test('validates valid Monero address', () {
        final validator = AddressValidator(type: CryptoCurrency.xmr);
        expect(
            validator.isValid(
                '85s6zfxGAkdCN21h566R8EFDSfThxCrFiEkhw3JEtaXN2DDfahABLXTjRj385Ro7om5saGWJG7iuE6EyW5MYcoz93DLvNqh'),
            isTrue);
      });

      test('rejects invalid Monero address', () {
        final validator = AddressValidator(type: CryptoCurrency.xmr);
        expect(validator.isValid('invalid_address'), isFalse);
        expect(
            validator.isValid(
                '85s6zfxGAkdCN21h566R8EFDSfThxCrFiEkhw3JEtaXN2DDfahABLXTjRj385Ro7om5saGWJG7iuE6EyW5MYcoz93DLvNq'),
            isFalse); // Too short
      });

      test('validates valid Litecoin address', () {
        final validator = AddressValidator(type: CryptoCurrency.ltc);
        expect(validator.isValid('ltc1qzvxlvlk8wsmue0np20eh3d3qxsusx9jstf8qw8'), isTrue);
        expect(
            validator.isValid(
                'ltcmweb1qqt9hqch2d0vfdsvt4tf27gullem2tcd57xxrvta9xwvfmwdkn4927q6d8sq6ftw7lkqdkr5g36eqn7w06edgq8tz7gy0nv5d4lhajctkzuath23a'),
            isTrue);
      });

      test('rejects invalid Litecoin address', () {
        final validator = AddressValidator(type: CryptoCurrency.ltc);
        expect(validator.isValid('invalid_address'), isFalse);
        expect(validator.isValid('ltc1qzvxlvlk8wsmue0np20eh3d3qxsusxCakeWallet'), isFalse);
      });
    });

    group('silentPaymentAddressPatternMainnet', () {
      test('returns a non-empty pattern', () {
        final pattern = AddressValidator.silentPaymentAddressPatternMainnet;
        expect(pattern, isNotEmpty);
      });
    });

    group('silentPaymentAddressPatternTestnet', () {
      test('returns a non-empty pattern', () {
        final pattern = AddressValidator.silentPaymentAddressPatternTestnet;
        expect(pattern, isNotEmpty);
      });
    });

    group('mWebAddressPattern', () {
      test('returns a non-empty pattern', () {
        final pattern = AddressValidator.mWebAddressPattern;
        expect(pattern, isNotEmpty);
      });
    });
  });
}
