import "package:cake_wallet/exchange/provider/stealthex/stealthex_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("StealthExRange", () {
    test("parses rates_range field by field", () {
      final raw = fixtureMap("stealthex", "rates_range");
      final range = StealthExRange.fromJson(raw);

      expect(range.minAmount, (raw["min_amount"] as num).toDouble());
      expect(range.maxAmount, raw["max_amount"]);
    });

    test("a null max_amount means no upper limit", () {
      final raw = fixtureMap("stealthex", "rates_range");

      expect(raw["max_amount"], isNull);
      expect(StealthExRange.fromJson(raw).maxAmount, isNull);
    });
  });

  group("StealthExEstimate", () {
    test("parses rates_estimated_amount field by field", () {
      final raw = fixtureMap("stealthex", "rates_estimated_amount");
      final estimate = StealthExEstimate.fromJson(raw);

      expect(estimate.estimatedAmount, (raw["estimated_amount"] as num).toDouble());
      expect(estimate.rate, isNull, reason: "a rate object only comes back for a fixed rate");
    });
  });

  group("StealthExErrorResponse", () {
    test("parses the no pair body", () {
      final raw = fixtureMap("stealthex", "rates_range_no_pair");
      final error = StealthExErrorResponse.fromJson(raw);

      expect(error.err.kind, StealthExErrorKind.noPair);
      expect(error.err.details, raw["err"]["details"]);
    });

    test("every documented kind maps to its enum value", () {
      const kinds = {
        "NoPair": StealthExErrorKind.noPair,
        "NotFound": StealthExErrorKind.notFound,
        "NotAllowed": StealthExErrorKind.notAllowed,
        "NoExchangeRoute": StealthExErrorKind.noExchangeRoute,
        "RouteIsDisabled": StealthExErrorKind.routeIsDisabled,
        "MarketUnavailable": StealthExErrorKind.marketUnavailable,
        "InvalidAmount": StealthExErrorKind.invalidAmount,
        "InvalidData": StealthExErrorKind.invalidData,
        "RateId": StealthExErrorKind.rateId,
        "ExtraId": StealthExErrorKind.extraId,
        "NoUserApiKey": StealthExErrorKind.noUserApiKey,
        "RoutesMismatch": StealthExErrorKind.routesMismatch,
      };

      kinds.forEach((wire, expected) {
        final error = StealthExErrorResponse.fromJson({
          "err": {"kind": wire, "details": "..."},
        });

        expect(error.err.kind, expected, reason: wire);
      });
    });

    test("an unrecognised kind falls back to unknown", () {
      final error = StealthExErrorResponse.fromJson({
        "err": {"kind": "SomethingNew", "details": "..."},
      });

      expect(error.err.kind, StealthExErrorKind.unknown);
    });
  });

  group("StealthExExchange", () {
    for (final name in ["exchange", "create_exchange"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("stealthex", name);
        final exchange = StealthExExchange.fromJson(raw);

        expect(exchange.id, raw["id"]);
        expect(exchange.status, TradeState.deserialize(raw: raw["status"] as String));
        expect(exchange.rate, StealthExRateType.floating);
        expect(exchange.refundAddress, raw["refund_address"]);
        expect(exchange.refundExtraId, raw["refund_extra_id"]);
        expect(exchange.createdAt, DateTime.parse(raw["created_at"] as String));
        expect(exchange.expiresAt, isNull, reason: "only a fixed rate exchange expires");

        for (final side in ["deposit", "withdrawal"]) {
          final rawSide = raw[side] as Map<String, dynamic>;
          final parsed = side == "deposit" ? exchange.deposit : exchange.withdrawal;

          expect(parsed.symbol, rawSide["symbol"]);
          expect(parsed.network, rawSide["network"]);
          expect(parsed.amount, (rawSide["amount"] as num).toDouble());
          expect(parsed.expectedAmount, (rawSide["expected_amount"] as num).toDouble());
          expect(parsed.address, rawSide["address"]);
          expect(parsed.extraId, rawSide["extra_id"]);
          expect(parsed.txHash, rawSide["tx_hash"]);
          expect(parsed.addressExplorerUrl, rawSide["address_explorer_url"]);
          expect(parsed.txExplorerUrl, rawSide["tx_explorer_url"]);
        }
      });
    }

    test("the exchange fixture is the one the create fixture made", () {
      final created = StealthExExchange.fromJson(fixtureMap("stealthex", "create_exchange"));
      final fetched = StealthExExchange.fromJson(fixtureMap("stealthex", "exchange"));

      expect(fetched.id, created.id);
      expect(fetched.deposit.address, created.deposit.address);
    });

    test("nothing has been sent yet, so neither side has a hash", () {
      final exchange = StealthExExchange.fromJson(fixtureMap("stealthex", "exchange"));

      expect(exchange.deposit.txHash, isNull);
      expect(exchange.withdrawal.txHash, isNull);
      expect(exchange.status, TradeState.waiting);
    });
  });

  group("requests", () {
    test("StealthExRangeRequest nests the route as symbol and network pairs", () {
      final json = const StealthExRangeRequest(
        route: StealthExRoute(from: CryptoCurrency.btc, to: CryptoCurrency.xmr),
        estimation: StealthExEstimation.direct,
        rate: StealthExRateType.floating,
      ).toJson();

      expect(json, {
        "route": {
          "from": {"symbol": "btc", "network": "mainnet"},
          "to": {"symbol": "xmr", "network": "mainnet"},
        },
        "estimation": "direct",
        "rate": "floating",
      });
    });

    test("StealthExEstimateRequest carries the amount and the partner fee", () {
      final json = const StealthExEstimateRequest(
        route: StealthExRoute(from: CryptoCurrency.btc, to: CryptoCurrency.xmr),
        amount: 0.01,
        estimation: StealthExEstimation.reversed,
        rate: StealthExRateType.fixed,
        additionalFeePercent: 0.5,
      ).toJson();

      expect(json["amount"], 0.01);
      expect(json["estimation"], "reversed");
      expect(json["rate"], "fixed");
      expect(json["additional_fee_percent"], 0.5);
    });

    test("StealthExEstimateRequest omits the fee when there is none", () {
      final json = const StealthExEstimateRequest(
        route: StealthExRoute(from: CryptoCurrency.btc, to: CryptoCurrency.xmr),
        amount: 0.01,
        estimation: StealthExEstimation.direct,
        rate: StealthExRateType.floating,
      ).toJson();

      expect(json.containsKey("additional_fee_percent"), isFalse);
    });

    test("StealthExCreateExchangeRequest serializes the addresses and rate id", () {
      final json = const StealthExCreateExchangeRequest(
        route: StealthExRoute(from: CryptoCurrency.eth, to: CryptoCurrency.usdterc20),
        amount: 0.01,
        estimation: StealthExEstimation.direct,
        rate: StealthExRateType.fixed,
        address: "0xpayout",
        rateId: "rate-id",
        refundAddress: "0xrefund",
      ).toJson();

      expect(json["address"], "0xpayout");
      expect(json["rate_id"], "rate-id");
      expect(json["refund_address"], "0xrefund");
      expect(json["route"], {
        "from": {"symbol": "eth", "network": "mainnet"},
        "to": {"symbol": "usdt", "network": "eth"},
      });
      expect(json.containsKey("extra_id"), isFalse);
      expect(json.containsKey("refund_extra_id"), isFalse);
    });
  });

  group("StealthExCurrencyConverter", () {
    const converter = StealthExCurrencyConverter();

    test("a native coin has the mainnet network", () {
      expect(converter.toJson(CryptoCurrency.btc), {"symbol": "btc", "network": "mainnet"});
      expect(converter.toJson(CryptoCurrency.xmr), {"symbol": "xmr", "network": "mainnet"});
    });

    test("a token carries its own network, lowercased from the tag", () {
      expect(converter.toJson(CryptoCurrency.usdterc20), {"symbol": "usdt", "network": "eth"});
    });

    test("keeps the special cases the provider had", () {
      expect(converter.toJson(CryptoCurrency.usdcEPoly)["symbol"], "usdce");
      expect(converter.toJson(CryptoCurrency.arb)["network"], "arbitrum");
      expect(converter.toJson(CryptoCurrency.maticpoly)["network"], "mainnet");
    });

    test("the POLY branch is dead now that the tag is POL, so polygon goes out as pol", () {
      // the mapping came over from the old provider, which special cased a "POLY" tag to
      // "matic". nothing carries that tag any more, so polygon tokens serialize as "pol"
      expect(CryptoCurrency.usdcpoly.tag, "POL");
      expect(converter.toJson(CryptoCurrency.usdcpoly)["network"], "pol");
      expect(CryptoCurrency.all.where((c) => c.tag == "POLY"), isEmpty);
    });

    test("reads a native coin back, treating mainnet as no tag", () {
      expect(
        converter.fromJson({"symbol": "btc", "network": "mainnet"}),
        CryptoCurrency.btc,
      );
    });

    test("reads a token back from its network", () {
      expect(converter.fromJson({"symbol": "usdt", "network": "eth"}), CryptoCurrency.usdterc20);
    });

    test("round trips every currency the provider can quote", () {
      for (final currency in [
        CryptoCurrency.btc,
        CryptoCurrency.xmr,
        CryptoCurrency.eth,
        CryptoCurrency.ltc,
        CryptoCurrency.usdterc20,
      ]) {
        expect(converter.fromJson(converter.toJson(currency)), currency, reason: currency.title);
      }
    });

    test("throws on a currency it cannot map", () {
      expect(
        () => converter.fromJson({"symbol": "nosuchcoin", "network": "nosuchchain"}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
