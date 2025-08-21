import 'package:cake_wallet/core/universal_address_detector.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UniversalAddressDetector', () {
    group('Bitcoin Address Detection', () {
      test('detects Bitcoin P2PKH address', () {
        const address = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btc);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, address);
      });

      test('detects Bitcoin P2SH address', () {
        const address = '3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btc);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, address);
      });

      test('detects Bitcoin Bech32 address', () {
        const address = 'bc1q56x5hha4mm35wmnqmj8ajkgxykf9cnjmrv3tmj';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btc);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, address);
      });

      test('detects Bitcoin URI with amount', () {
        const uri = 'bitcoin:1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa?amount=0.001';
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btc);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
        expect(result.amount, '0.001');
      });
    });

    group('Monero Address Detection', () {
      test('detects Monero address', () {
        const address =
            '48HHtdQvxyH5jwX5N6fAQD6rxx7EQT7GKZvsixtgJRkRaD8wHqwKp6eGSuStiUN5MHXR19vF3W4Jc7MumryYTTH7LGTfanS';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.xmr);
        expect(result.detectedWalletType, WalletType.monero);
        expect(result.address, address);
      });

      test('detects Monero integrated address', () {
        const address =
            '88HHtdQvxyH5jwX5N6fAQD6rxx7EQT7GKZvsixtgJRkRaD8wHqwKp6eGSuStiUN5MHXR19vF3W4Jc7MumryYTTH7LGTfanS';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.xmr);
        expect(result.detectedWalletType, WalletType.monero);
        expect(result.address, address);
      });
    });

    group('Ethereum Address Detection', () {
      test('detects Ethereum address', () {
        const address = '0xAE3A8C650CDFad88e87621F8371642bd4B578601';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.eth);
        expect(result.detectedWalletType, WalletType.ethereum);
        expect(result.address, address);
      });

      test('detects Ethereum URI', () {
        const uri = 'ethereum:0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6?value=1000000000000000000';
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.eth);
        expect(result.detectedWalletType, WalletType.ethereum);
        expect(result.address, '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6');
        expect(result.amount, '1');
      });
    });

    group('Litecoin Address Detection', () {
      test('detects Litecoin Bech32 address', () {
        const address = 'ltc1qk4ewr0fjgltsvwymfz7az66q2w73qj0z06cj36';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.ltc);
        expect(result.detectedWalletType, WalletType.litecoin);
        expect(result.address, address);
      });
    });

    group('Bitcoin Cash Address Detection', () {
      test('detects Bitcoin Cash address', () {
        const address = 'bitcoincash:qqdjjymdpfmqzq69t4vdcxsmrzmlzlwgaucwm878p5';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.bch);
        expect(result.detectedWalletType, WalletType.bitcoinCash);
        expect(result.address, 'qqdjjymdpfmqzq69t4vdcxsmrzmlzlwgaucwm878p5');
      });

      test('detects Bitcoin Cash address without prefix', () {
        const address = 'qqdjjymdpfmqzq69t4vdcxsmrzmlzlwgaucwm878p5';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.bch);
        expect(result.detectedWalletType, WalletType.bitcoinCash);
        expect(result.address, address);
      });
    });

    group('Nano Address Detection', () {
      test('detects Nano address', () {
        const address = 'nano_3gsnr4a3ku3k9hjczobbr5fhhz94c66yczxbpjukeyy3edpxiyp1tqi8angm';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.nano);
        expect(result.detectedWalletType, WalletType.nano);
        expect(result.address, address);
      });
    });

    group('Solana Address Detection', () {
      test('detects Solana address', () {
        const address = '7TSTXnQZxQDA4JoNqs4DqVqE7oNWk2kmHkMT6DD6vw2S';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.sol);
        expect(result.detectedWalletType, WalletType.solana);
        expect(result.address, address);
      });
    });

    group('Tron Address Detection', () {
      test('detects Tron address', () {
        const address = 'TF7yQKp7pwLBSXBXthcrXMqTyjtvkJK28V';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.trx);
        expect(result.detectedWalletType, WalletType.tron);
        expect(result.address, address);
      });
    });

    group('Wownero Address Detection', () {
      test('detects Wownero address', () {
        const address =
            'WW3uV9iygJjefkU5bmzeoCFkqZEwg1xC92BKcUFJMcSVF1HQoK4ehDTJScTU28CYvJaZ9sZt5xH8qF1n6vXqXE9G2KMC9JsKh';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.wow);
        expect(result.detectedWalletType, WalletType.wownero);
        expect(result.address, address);
      });
    });

    group('Zano Address Detection', () {
      test('detects Zano address', () {
        const address =
            'ZxDREZKHjUAUkRpWrHV9AjJHe12RhtoY9TjUUx2EznNNdwJK9yiHEhuQkqGYnyDXRnFC3Uehu6kLGZmiQab8fWoQ1JrLsuJ1i';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.zano);
        expect(result.detectedWalletType, WalletType.zano);
        expect(result.address, address);
      });

      test('detects Zano alias', () {
        const address = '@testuser';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.zano);
        expect(result.detectedWalletType, WalletType.zano);
        expect(result.address, address);
      });
    });

    group('Decred Address Detection', () {
      test('detects Decred address', () {
        const address = 'DsW4ZtRV1DcPCuKXVVtGnCy3AtAZHg5N8nR';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.dcr);
        expect(result.detectedWalletType, WalletType.decred);
        expect(result.address, address);
      });
    });

    group('Invalid Address Detection', () {
      test('handles empty input', () {
        const address = '';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, false);
        expect(result.errorMessage, 'Empty input provided');
      });

      test('handles whitespace only', () {
        const address = '   ';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, false);
        expect(result.errorMessage, 'Empty input provided');
      });

      test('handles random text', () {
        const address = 'this_is_not_an_address_123';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, false);
        expect(result.errorMessage, 'Unable to detect valid cryptocurrency address');
      });
    });
  });
}
