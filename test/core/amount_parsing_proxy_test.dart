import "package:cake_wallet/core/amount_parsing_proxy.dart";
import "package:cake_wallet/entities/bitcoin_amount_display_mode.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("AmountParsingProxy", () {
    group("BitcoinAmountDisplayMode.satoshi", () {
      final amountParsingProxy = AmountParsingProxy(BitcoinAmountDisplayMode.satoshi);

      group("getCryptoInputAmount", () {
        test("Amount should be parsed from Satoshi for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.btc);
          expect(amount, "0.000001");
        });

        test("Amount should be parsed from Satoshi for Bitcoin Lightning", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.btcln);
          expect(amount, "0.000001");
        });

        test("Amount should not be parsed from Satoshi for Ethereum", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.eth);
          expect(amount, "100");
        });
      });

      group("getCryptoOutputAmount", () {
        test("Amount should be formated to Satoshi for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("0.000001", CryptoCurrency.btc);
          expect(amount, "100");
        });

        test("Amount should be formated to Satoshi for Bitcoin Lightning", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("100", CryptoCurrency.btcln);
          expect(amount, "10000000000");
        });

        test("Amount should not be formated to Satoshi for Ethereum", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("100", CryptoCurrency.eth);
          expect(amount, "100");
        });
      });
    });

    group("BitcoinAmountDisplayMode.bitcoin", () {
      final amountParsingProxy = AmountParsingProxy(BitcoinAmountDisplayMode.bitcoin);

      group("getCryptoInputAmount", () {
        test("Amount should not change for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoInputAmount("0.000001", CryptoCurrency.btc);
          expect(amount, "0.000001");
        });

        test("Amount should not change for Bitcoin: potentially wrong input Satoshi", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.btc);
          expect(amount, "100");
        });

        test("Amount should not change for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoInputAmount("0.000001", CryptoCurrency.btcln);
          expect(amount, "0.000001");
        });

        test("Amount should not change for Bitcoin Lightning: potentially wrong input Satoshi", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.btcln);
          expect(amount, "100");
        });

        test("Amount should not change on ETH", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.eth);
          expect(amount, "100");
        });
      });

      group("getCryptoOutputAmount", () {
        test("Amount should not be formated to Satoshi for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("0.000001", CryptoCurrency.btc);
          expect(amount, "0.000001");
        });

        test("Amount should not be formated to Satoshi for Bitcoin Lightning", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("100", CryptoCurrency.btcln);
          expect(amount, "100");
        });

        test("Amount should not be formated to Satoshi for Ethereum", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("100", CryptoCurrency.eth);
          expect(amount, "100");
        });
      });
    });

    group("BitcoinAmountDisplayMode.satoshiForLightning", () {
      final amountParsingProxy = AmountParsingProxy(BitcoinAmountDisplayMode.satoshiForLightning);

      group("getCryptoInputAmount", () {
        test("Amount should not change for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.btc);
          expect(amount, "100");
        });

        test("Amount should get formated from Satoshi for Bitcoin Lightning", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.btcln);
          expect(amount, "0.000001");
        });

        test("Amount should not change for Ethereum", () {
          final amount = amountParsingProxy.getCryptoInputAmount("100", CryptoCurrency.eth);
          expect(amount, "100");
        });
      });

      group("getCryptoOutputAmount", () {
        test("Amount should not be formated to Satoshi for Bitcoin", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("0.000001", CryptoCurrency.btc);
          expect(amount, "0.000001");
        });

        test("Amount should be formated to Satoshi for Bitcoin Lightning", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("0.000001", CryptoCurrency.btcln);
          expect(amount, "100");
        });

        test("Amount should not be formated to Satoshi for Ethereum", () {
          final amount = amountParsingProxy.getCryptoOutputAmount("100", CryptoCurrency.eth);
          expect(amount, "100");
        });
      });
    });
  });
}
