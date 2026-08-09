import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/spl_token.dart';
import 'package:cw_core/tron_token.dart';
import 'package:flutter_test/flutter_test.dart';

String chars(int count, [String char = 'a']) => List.filled(count, char).join();

void main() {
  group('ExchangeViewModelBase.validateSwapAddresses', () {
    setUpAll(() => S.current = S());

    const btcAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
    final xmrAddress = '4${chars(94)}';

    String? validate(
      CryptoCurrency depositCurrency,
      CryptoCurrency receiveCurrency, {
      required String depositAddress,
      required String receiveAddress,
      bool validateDepositAddress = true,
      bool validateReceiveAddress = true,
    }) => ExchangeViewModelBase.validateSwapAddresses(
      depositCurrency: depositCurrency,
      receiveCurrency: receiveCurrency,
      depositAddress: depositAddress,
      receiveAddress: receiveAddress,
      validateDepositAddress: validateDepositAddress,
      validateReceiveAddress: validateReceiveAddress,
    );

    test('accepts valid external addresses', () {
      expect(
        validate(
          CryptoCurrency.btc,
          CryptoCurrency.xmr,
          depositAddress: btcAddress,
          receiveAddress: xmrAddress,
        ),
        isNull,
      );
    });

    test('allows empty provider-owned internal addresses', () {
      expect(
        validate(
          CryptoCurrency.btc,
          CryptoCurrency.xmr,
          depositAddress: '',
          receiveAddress: '',
          validateDepositAddress: false,
          validateReceiveAddress: false,
        ),
        isNull,
      );
    });

    test('rejects empty, malformed, and wrong-currency addresses', () {
      for (final receiveAddress in [
        '',
        'not-an-address',
        btcAddress,
        'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',
      ]) {
        expect(
          validate(
            CryptoCurrency.btc,
            CryptoCurrency.xmr,
            depositAddress: btcAddress,
            receiveAddress: receiveAddress,
          ),
          S.current.error_text_address,
        );
      }
    });

    test('rejects a wrong-network Bitcoin refund address', () {
      expect(
        validate(
          CryptoCurrency.btc,
          CryptoCurrency.xmr,
          depositAddress: 'tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx',
          receiveAddress: xmrAddress,
        ),
        S.current.error_text_address,
      );
    });

    final erc20 = Erc20Token(
      name: 'Cake',
      symbol: 'CAKE',
      contractAddress: '0x${chars(40)}',
      decimal: 18,
    );
    final spl = SPLToken(
      name: 'Cake SPL',
      symbol: 'CAKESPL',
      mintAddress: chars(43),
      mint: chars(43),
      decimal: 9,
    );
    final tron = TronToken(
      name: 'Cake TRON',
      symbol: 'CAKETRX',
      contractAddress: 'T${chars(33)}',
      decimal: 6,
    );

    final chainCases = <({String name, CryptoCurrency currency, String valid, String invalid})>[
      (
        name: 'Ethereum',
        currency: CryptoCurrency.eth,
        valid: '0x${chars(40)}',
        invalid: '0x${chars(39)}z',
      ),
      (
        name: 'BNB on BSC',
        currency: CryptoCurrency.bnb,
        valid: '0x${chars(40)}',
        invalid: 'bnb1${chars(38)}',
      ),
      (name: 'ERC-20 token', currency: erc20, valid: '0x${chars(40)}', invalid: '0x${chars(39)}z'),
      (name: 'SPL token', currency: spl, valid: chars(43), invalid: '${chars(42)}0'),
      (name: 'TRON token', currency: tron, valid: 'T${chars(33)}', invalid: 't${chars(33)}'),
    ];

    for (final chainCase in chainCases) {
      test('enforces ${chainCase.name} address format', () {
        expect(
          validate(
            chainCase.currency,
            chainCase.currency,
            depositAddress: chainCase.valid,
            receiveAddress: chainCase.valid,
          ),
          isNull,
        );
        expect(
          validate(
            chainCase.currency,
            chainCase.currency,
            depositAddress: chainCase.invalid,
            receiveAddress: chainCase.valid,
          ),
          S.current.error_text_address,
        );
      });
    }

    group('Lightning network semantics', () {
      final lnbc = 'lnbc${chars(30)}';

      test('accepts mainnet invoices only for btcln', () {
        expect(
          validate(
            CryptoCurrency.btc,
            CryptoCurrency.btcln,
            depositAddress: btcAddress,
            receiveAddress: lnbc,
          ),
          isNull,
        );

        for (final invalid in [
          'lntb${chars(30)}',
          'lnbcrt${chars(30)}',
          'lnbs${chars(30)}',
          'lnurl${chars(30)}',
        ]) {
          expect(
            validate(
              CryptoCurrency.btc,
              CryptoCurrency.btcln,
              depositAddress: btcAddress,
              receiveAddress: invalid,
            ),
            S.current.error_text_address,
          );
        }
      });

      test('rejects Lightning values for on-chain Bitcoin', () {
        for (final invalid in [lnbc, 'lightning:$lnbc', 'lnurl${chars(30)}']) {
          expect(
            validate(
              CryptoCurrency.btc,
              CryptoCurrency.btc,
              depositAddress: btcAddress,
              receiveAddress: invalid,
            ),
            S.current.error_text_address,
          );
        }
      });
    });

    group('unsupported exchange address types', () {
      final silentPayment = 'sp1${chars(113)}';
      final mweb = 'ltcmweb1q${chars(94, 'q')}';

      for (final addressCase in [
        (name: 'Silent Payment', address: silentPayment),
        (name: 'MWEB', address: mweb),
      ]) {
        test('rejects ${addressCase.name} refund and receive addresses', () {
          expect(
            validate(
              CryptoCurrency.btc,
              CryptoCurrency.xmr,
              depositAddress: addressCase.address,
              receiveAddress: xmrAddress,
            ),
            '${addressCase.name} ${S.current.address_not_allowed_as_refund}',
          );
          expect(
            validate(
              CryptoCurrency.btc,
              CryptoCurrency.xmr,
              depositAddress: btcAddress,
              receiveAddress: addressCase.address,
            ),
            '${addressCase.name} ${S.current.address_not_allowed_as_receive}',
          );
        });
      }
    });
  });
}
