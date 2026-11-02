import "package:cake_wallet/cake_pay/src/models/cake_pay_order.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_stablecoin.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

Map<String, dynamic> _stablecoinEntry(List<Map<String, String>> networks) => {
      "requires_quote": true,
      "networks": networks,
    };

Map<String, dynamic> _paymentData(Map<String, dynamic> entries) => {
      ...entries,
      "invoice_time": 1790714513000,
      "expiration_time": 1790715413000,
      "commission": null,
    };

void main() {
  group("PaymentData stablecoins", () {
    test("parses each coin's own networks", () {
      final paymentData = PaymentData.fromMap(
        _paymentData({
          "USDT": _stablecoinEntry([
            {"chain": "tron", "name": "Tron"},
            {"chain": "bsc", "name": "BNB Chain"},
          ]),
          "USDC": _stablecoinEntry([
            {"chain": "base", "name": "Base"},
            {"chain": "avalanche", "name": "Avalanche"},
          ]),
        }),
      );

      final networks = {
        for (final coin in paymentData.stablecoins)
          coin.method.name: [for (final network in coin.networks) network.id],
      };
      expect(networks, {
        "USDC": ["base", "avalanche"],
        "USDT": ["tron", "bsc"],
      });
    });

    test("skips coins that do not require a quote or offer no network", () {
      final paymentData = PaymentData.fromMap(
        _paymentData({
          "USDC": _stablecoinEntry([]),
          "USDT": {
            ..._stablecoinEntry([
              {"chain": "tron", "name": "Tron"},
            ]),
            "requires_quote": false,
          },
        }),
      );

      expect(paymentData.stablecoins, isEmpty);
    });

    test("is empty for orders without stablecoins", () {
      final paymentData = PaymentData.fromMap(
        _paymentData({
          "BTC": {
            "amount_from": 0.0003,
            "price": "0.0003",
            "paymentUrls": {"BIP21": "bitcoin:bc1qexample?amount=0.0003"},
            "address": "bc1qexample",
          },
        }),
      );

      expect(paymentData.stablecoins, isEmpty);
      expect(paymentData.btc?.address, "bc1qexample");
    });

    test("leaves a chain the app doesn't know without a currency", () {
      expect(const StablecoinNetwork(id: "optimism").nativeCurrency, isNull);
    });
  });

  group("StablecoinNetwork", () {
    test("maps backend network IDs to supported wallet currencies", () {
      for (final entry in const {
        "ethereum": CryptoCurrency.eth,
        "base": CryptoCurrency.baseEth,
        "arbitrum": CryptoCurrency.arbEth,
        "polygon": CryptoCurrency.maticpoly,
        "bsc": CryptoCurrency.bnb,
        "tron": CryptoCurrency.trx,
        "solana": CryptoCurrency.sol,
      }.entries) {
        expect(StablecoinNetwork(id: entry.key).nativeCurrency, entry.value);
        expect(StablecoinNetwork.supportsNetwork(entry.value), isTrue);
      }
      for (final currency in [
        CryptoCurrency.btc,
        CryptoCurrency.xmr,
        CryptoCurrency.ltc,
        CryptoCurrency.zec,
      ]) {
        expect(StablecoinNetwork.supportsNetwork(currency), isFalse);
      }
    });
  });

  group("CakePayStablecoinQuote", () {
    test("parses the quote response", () {
      final quote = CakePayStablecoinQuote.fromMap({
        "address": "0x6490e244136af11ca7c7ff8997916e01e4a39b1c",
        "amount": "25.061219",
        "contract": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "offered_until": 1790719186000,
      });

      expect(quote.address, "0x6490e244136af11ca7c7ff8997916e01e4a39b1c");
      expect(quote.amount, "25.061219");
      expect(quote.contract, "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913");
      expect(quote.offeredUntil, DateTime.fromMillisecondsSinceEpoch(1790719186000));
    });

    test("has no expiry when offered_until is 0 and no contract when it is null", () {
      final quote = CakePayStablecoinQuote.fromMap({
        "address": "TXyzDepositAddress",
        "amount": "28.23",
        "contract": null,
        "offered_until": 0,
      });

      expect(quote.offeredUntil, isNull);
      expect(quote.contract, isNull);
    });
  });
}
