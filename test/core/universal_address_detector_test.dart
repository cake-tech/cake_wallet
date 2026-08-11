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

      test('detects Lightning invoice', () {
        const invoice =
            'lnbc1u1p3zj7j8pp5vkwxc4vxfzgzxcjzk5ksp0l7jgrgzmqxqmexxp8e8gfqk6s0knnqdlc35hsggzypnxw7xxxnrvd3hscqzpgxqrrsssp5txs5g8vkdmdtnm8g5v9m3u094nnxkl0jjf38jj5xn2pptxlqkwn7gpgfkt7q6z0frcj7vjy4mv7659hccln2e0gzt4ufnsukxcnknh7e58kwnr8pk6kgv6vrghcpld2z5n';
        final result = UniversalAddressDetector.detectAddress(invoice);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btcln);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, invoice);
      });

      test('detects Lightning address', () {
        const address = 'alice@lightning.com';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btcln);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, address);
      });

      test('detects LNURL format', () {
        const address = 'LNURL1DP68GURN8GHJ7UM9WFMXCCRVFH8RHYEE5QDKURZQDF8JUK6RKCE0E';
        final result = UniversalAddressDetector.detectAddress(address);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.btcln);
        expect(result.detectedWalletType, WalletType.bitcoin);
        expect(result.address, address);
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

    group("EVM chainId URI Detection", () {
      const recipient = "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6";
      const contract = "0xdAC17F958D2ee523a2206206994597C13D831ec7";

      test("detects the polygon network from an ERC-681 chainId", () {
        const uri = "ethereum:$recipient@137?value=1.0e18";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedWalletType, WalletType.polygon);
        expect(result.chainId, 137);
        expect(result.address, recipient);
        expect(result.amount, "1");
      });

      test("detects the base network from an ERC-681 chainId", () {
        const uri = "ethereum:$recipient@8453";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedWalletType, WalletType.base);
        expect(result.chainId, 8453);
        expect(result.address, recipient);
      });

      test("extracts the recipient from an ERC-681 token transfer URI", () {
        const uri = "ethereum:$contract@1/transfer?address=$recipient&uint256=1000000";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedWalletType, WalletType.ethereum);
        expect(result.chainId, 1);
        expect(result.address, recipient);
      });

      test("preserves an unsupported chainId so routing can reject it", () {
        const uri = "ethereum:$recipient@999999";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedWalletType, WalletType.ethereum);
        expect(result.chainId, 999999);
        expect(result.address, recipient);
      });
    });

    group("Token URI Detection", () {
      test("detects a Solana pay URI with an spl-token param", () {
        const address = "4Nd1mYvNQyJ8BDVXLgkvSGpVdQMZ3hxwVFkfwXNq6Wgk";
        const uri =
            "solana:$address?amount=1.5&spl-token=Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.sol);
        expect(result.detectedWalletType, WalletType.solana);
        expect(result.address, address);
        expect(result.amount, "1.5");
      });

      test("detects a Tron URI with a token param", () {
        const address = "TNPeeaaFB7K9cmo4uQpcU32zGK8G1NYqeL";
        const uri = "tron:$address?amount=2&token=TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedCurrency, CryptoCurrency.trx);
        expect(result.detectedWalletType, WalletType.tron);
        expect(result.address, address);
        expect(result.amount, "2");
      });

      test("detects a bare Solana URI without params", () {
        const address = "4Nd1mYvNQyJ8BDVXLgkvSGpVdQMZ3hxwVFkfwXNq6Wgk";
        const uri = "solana:$address";
        final result = UniversalAddressDetector.detectAddress(uri);

        expect(result.isValid, true);
        expect(result.detectedWalletType, WalletType.solana);
        expect(result.address, address);
        expect(result.amount, "");
      });
    });
  });
}
