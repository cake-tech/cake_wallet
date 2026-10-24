import "package:cake_wallet/cake_pay/src/models/cake_pay_order.dart";
import "package:cake_wallet/cake_pay/src/models/cake_pay_stablecoin_quote.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:flutter_test/flutter_test.dart";

Map<String, dynamic> _stablecoinEntry(List<Map<String, String>> networks) => {
      "amount_from": 25.0,
      "price": "25.0",
      "paymentUrls": {"BIP21": ""},
      "address": "",
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
          coin.paymentMethod: [for (final network in coin.networks) (network.chain, network.name)],
      };
      expect(networks, {
        "USDC": [("base", "Base"), ("avalanche", "Avalanche")],
        "USDT": [("tron", "Tron"), ("bsc", "BNB Chain")],
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
      expect(const StablecoinNetwork(chain: "optimism", name: "Optimism").currency, isNull);
    });

    test("gives every network a distinct icon", () {
      const chains = [
        "ethereum",
        "base",
        "arbitrum",
        "polygon",
        "bsc",
        "avalanche",
        "tron",
        "solana",
      ];
      final icons = {
        for (final chain in chains)
          networkIconPathForCurrency(StablecoinNetwork(chain: chain, name: chain).currency!),
      };

      expect(icons, isNot(contains(null)));
      expect(icons, hasLength(chains.length));
    });
  });

  group("CakePayStablecoinQuote", () {
    test("parses the quote response", () {
      final quote = CakePayStablecoinQuote.fromMap({
        "payment_method": "USDC",
        "chain": "base",
        "chain_name": "Base",
        "address": "0x6490e244136af11ca7c7ff8997916e01e4a39b1c",
        "amount": "25.061219",
        "fee": "0.061219000000000000",
        "contract": "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "payment_request":
            "ethereum:0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913@8453/transfer?address=0x6490e244136af11ca7c7ff8997916e01e4a39b1c&uint256=25061219",
        "offered_until": 1790719186000,
      });

      expect(quote.paymentMethod, "USDC");
      expect(quote.chainName, "Base");
      expect(quote.amount, "25.061219");
      expect(quote.fee, "0.061219");
      expect(quote.contract, "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913");
      expect(quote.offeredUntil, DateTime.fromMillisecondsSinceEpoch(1790719186000));
    });

    test("has no expiry when offered_until is 0 and no contract when it is null", () {
      final quote = CakePayStablecoinQuote.fromMap({
        "payment_method": "USDT",
        "chain": "tron",
        "chain_name": "Tron",
        "address": "TXyzDepositAddress",
        "amount": "28.23",
        "fee": "3.23",
        "contract": null,
        "payment_request": "TXyzDepositAddress",
        "offered_until": 0,
      });

      expect(quote.offeredUntil, isNull);
      expect(quote.contract, isNull);
    });
  });
}
