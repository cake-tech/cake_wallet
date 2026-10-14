import "dart:convert";

import "package:cake_wallet/exchange/provider/trocador/trocador_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("TrocadorCoin", () {
    test("parses every coin in coin", () {
      final raw = fixtureList("trocador", "coin");
      final coins = raw.map((e) => TrocadorCoin.fromJson(e as Map<String, dynamic>)).toList();

      expect(coins, hasLength(raw.length));

      for (var i = 0; i < raw.length; i++) {
        final rawCoin = raw[i] as Map<String, dynamic>;
        final coin = coins[i];

        expect(coin.name, rawCoin["name"]);
        expect(coin.ticker, rawCoin["ticker"]);
        expect(coin.network, rawCoin["network"]);
        expect(coin.memo, rawCoin["memo"]);
        expect(coin.image, rawCoin["image"]);
        expect(coin.minimum, rawCoin["minimum"].toString());
        expect(coin.maximum, rawCoin["maximum"].toString());
      }
    });

    test("the limits arrive as json numbers, not strings", () {
      final rawCoin = fixtureList("trocador", "coin").first as Map<String, dynamic>;

      expect(rawCoin["minimum"], isA<num>());
      expect(rawCoin["maximum"], isA<num>());
    });

    test("a limit stays parseable as an amount", () {
      final coin = TrocadorCoin.fromJson(
        fixtureList("trocador", "coin").first as Map<String, dynamic>,
      );

      expect(double.tryParse(coin.minimum!), isNotNull);
      expect(double.tryParse(coin.maximum!), isNotNull);
    });
  });

  group("TrocadorRate", () {
    test("parses new_rate field by field", () {
      final raw = fixtureMap("trocador", "new_rate");
      final rate = TrocadorRate.fromJson(raw);

      expect(rate.tradeId, raw["trade_id"]);
      expect(rate.date, DateTime.parse(raw["date"] as String));
      expect(rate.tickerFrom, raw["ticker_from"]);
      expect(rate.tickerTo, raw["ticker_to"]);
      expect(rate.coinFrom, raw["coin_from"]);
      expect(rate.coinTo, raw["coin_to"]);
      expect(rate.networkFrom, raw["network_from"]);
      expect(rate.networkTo, raw["network_to"]);
      expect(rate.amountFrom, raw["amount_from"].toString());
      expect(rate.amountTo, raw["amount_to"].toString());
      expect(rate.provider, raw["provider"]);
      expect(rate.fixed, raw["fixed"]);
      expect(rate.payment, raw["payment"]);
      expect(rate.status, TradeState.deserialize(raw: raw["status"] as String));
    });

    test("carries one quote per provider", () {
      final raw = fixtureMap("trocador", "new_rate");
      final rate = TrocadorRate.fromJson(raw);
      final rawQuotes = raw["quotes"]["quotes"] as List<dynamic>;

      expect(rate.quotes, isNotNull);
      expect(rate.quotes!.quotes, hasLength(rawQuotes.length));

      for (var i = 0; i < rawQuotes.length; i++) {
        expect(rate.quotes!.quotes![i].provider, (rawQuotes[i] as Map)["provider"]);
      }
    });

    test("the chosen provider is one of the quoted ones", () {
      final rate = TrocadorRate.fromJson(fixtureMap("trocador", "new_rate"));

      expect(
        rate.quotes!.quotes!.map((q) => q.provider),
        contains(rate.provider),
      );
    });

    test("a nested quote types its amounts as strings, unlike the top level", () {
      final raw = fixtureMap("trocador", "new_rate");

      expect(raw["amount_to"], isA<num>());
      expect((raw["quotes"]["quotes"] as List).first["amount_to"], isA<String>());
    });
  });

  group("TrocadorTrade", () {
    test("parses new_trade field by field", () {
      final raw = fixtureMap("trocador", "new_trade");
      final trade = TrocadorTrade.fromJson(raw);

      expect(trade.tradeId, raw["trade_id"]);
      expect(trade.date, DateTime.parse(raw["date"] as String));
      expect(trade.tickerFrom, raw["ticker_from"]);
      expect(trade.tickerTo, raw["ticker_to"]);
      expect(trade.coinFrom, raw["coin_from"]);
      expect(trade.coinTo, raw["coin_to"]);
      expect(trade.networkFrom, raw["network_from"]);
      expect(trade.networkTo, raw["network_to"]);
      expect(trade.amountFrom, raw["amount_from"].toString());
      expect(trade.amountTo, raw["amount_to"].toString());
      expect(trade.provider, raw["provider"]);
      expect(trade.fixed, raw["fixed"]);
      expect(trade.payment, raw["payment"]);
      expect(trade.status, TradeState.deserialize(raw: raw["status"] as String));
      expect(trade.addressProvider, raw["address_provider"]);
      expect(trade.addressProviderMemo, raw["address_provider_memo"]);
      expect(trade.addressUser, raw["address_user"]);
      expect(trade.addressUserMemo, raw["address_user_memo"]);
      expect(trade.refundAddress, raw["refund_address"]);
      expect(trade.refundAddressMemo, raw["refund_address_memo"]);
      expect(trade.password, raw["password"]);
      expect(trade.idProvider, raw["id_provider"]);
    });

    test("trade answers with a list of one", () {
      final raw = fixtureList("trocador", "trade");

      expect(raw, hasLength(1));

      final trade = TrocadorTrade.fromJson(raw.first as Map<String, dynamic>);
      final created = TrocadorTrade.fromJson(fixtureMap("trocador", "new_trade"));

      expect(trade.tradeId, created.tradeId, reason: "the status fixture chains off the create");
      expect(trade.addressProvider, created.addressProvider);
    });

    test("details carries the payout hash once there is one", () {
      final raw = fixtureList("trocador", "trade").first as Map<String, dynamic>;
      final trade = TrocadorTrade.fromJson(raw);

      expect(trade.details, isNotNull);
      expect(trade.details!.hashout, raw["details"]["hashout"]);
    });
  });

  group("TrocadorExchangesResponse", () {
    test("parses every partner in exchanges", () {
      final raw = fixtureMap("trocador", "exchanges");
      final response = TrocadorExchangesResponse.fromJson(raw);
      final rawList = raw["list"] as List<dynamic>;

      expect(response.list, hasLength(rawList.length));

      for (var i = 0; i < rawList.length; i++) {
        final rawPartner = rawList[i] as Map<String, dynamic>;
        final partner = response.list[i];

        expect(partner.name, rawPartner["name"]);
        expect(partner.insurance, rawPartner["insurance"]);
        expect(partner.enabledMarkup, rawPartner["enabledmarkup"]);
        expect(partner.eta, rawPartner["eta"]);
        expect(
          partner.rating,
          switch (rawPartner["rating"]) {
            "A" => TrocadorRating.a,
            "B" => TrocadorRating.b,
            "C" => TrocadorRating.c,
            "D" => TrocadorRating.d,
            _ => TrocadorRating.unknown,
          },
        );
      }
    });

    test("insurance parses whether it is an int or a double", () {
      final response = TrocadorExchangesResponse.fromJson(fixtureMap("trocador", "exchanges"));

      for (final partner in response.list) {
        expect(partner.insurance, anyOf(isNull, isA<double>()));
      }
    });

    test("an unrecognised rating falls back to unknown instead of throwing", () {
      const body = '{"name":"Nope","rating":"Z","insurance":0,"enabledmarkup":false,"eta":1}';
      final partner = TrocadorPartner.fromJson(json.decode(body) as Map<String, dynamic>);

      expect(partner.rating, TrocadorRating.unknown);
    });
  });

  group("requests", () {
    test("TrocadorCoinRequest serializes only what is set", () {
      expect(const TrocadorCoinRequest(ticker: "btc", name: "Bitcoin").toJson(),
          {"ticker": "btc", "name": "Bitcoin"});
      expect(const TrocadorCoinRequest(ticker: "btc").toJson(), {"ticker": "btc"});
    });

    test("TrocadorNewRateRequest writes python bools and letter ratings", () {
      final json = const TrocadorNewRateRequest(
        tickerFrom: "btc",
        networkFrom: "Mainnet",
        tickerTo: "xmr",
        networkTo: "Mainnet",
        amountFrom: "0.01",
        payment: false,
        minKycrating: TrocadorRating.c,
        markup: "0",
      ).toJson();

      expect(json["ticker_from"], "btc");
      expect(json["network_from"], "Mainnet");
      expect(json["ticker_to"], "xmr");
      expect(json["network_to"], "Mainnet");
      expect(json["amount_from"], "0.01");
      expect(json["payment"], "False", reason: "the api wants the python spelling");
      expect(json["min_kycrating"], "C");
      expect(json["markup"], "0");
      expect(json.containsKey("amount_to"), isFalse);
      expect(json.containsKey("best_only"), isFalse);
      expect(json.containsKey("min_logpolicy"), isFalse);
    });

    test("TrocadorNewRateRequest writes True for a payment", () {
      final json = const TrocadorNewRateRequest(
        tickerFrom: "btc",
        networkFrom: "Mainnet",
        tickerTo: "xmr",
        networkTo: "Mainnet",
        amountTo: "1",
        payment: true,
      ).toJson();

      expect(json["payment"], "True");
      expect(json["amount_to"], "1");
    });

    test("every value in a rate request query is a string, which Uri.https needs", () {
      final json = const TrocadorNewRateRequest(
        tickerFrom: "btc",
        networkFrom: "Mainnet",
        tickerTo: "xmr",
        networkTo: "Mainnet",
        amountFrom: "0.01",
        payment: false,
        bestOnly: true,
        minKycrating: TrocadorRating.a,
        minLogpolicy: TrocadorRating.b,
        markup: "1",
      ).toJson();

      expect(json.values.whereType<String>(), hasLength(json.length));
    });

    test("TrocadorNewTradeRequest serializes the trade parameters", () {
      final json = const TrocadorNewTradeRequest(
        id: "rate-id",
        tickerFrom: "eth",
        networkFrom: "ERC20",
        tickerTo: "usdt",
        networkTo: "ERC20",
        amountFrom: "0.01",
        address: "0xpayout",
        refund: "0xrefund",
        provider: "FixedFloat",
        fixed: false,
      ).toJson();

      expect(json["id"], "rate-id");
      expect(json["ticker_from"], "eth");
      expect(json["address"], "0xpayout");
      expect(json["refund"], "0xrefund");
      expect(json["provider"], "FixedFloat");
      expect(json["fixed"], "False");
      expect(json.containsKey("amount_to"), isFalse);
      expect(json.containsKey("webhook"), isFalse);
    });
  });

  group("TrocadorBoolConverter", () {
    const converter = TrocadorBoolConverter();

    test("takes a real json boolean", () {
      expect(converter.fromJson(true), isTrue);
      expect(converter.fromJson(false), isFalse);
    });

    test("takes the python spelling a nested quote uses", () {
      expect(converter.fromJson("True"), isTrue);
      expect(converter.fromJson("False"), isFalse);
      expect(converter.fromJson("true"), isTrue);
    });

    test("writes the python spelling", () {
      expect(converter.toJson(true), "True");
      expect(converter.toJson(false), "False");
    });
  });

  group("TrocadorAmountConverter", () {
    const converter = TrocadorAmountConverter();

    test("stringifies a number without losing digits", () {
      expect(converter.fromJson(0.01), "0.01");
      expect(converter.fromJson(1.7835711), "1.7835711");
      expect(converter.fromJson(20), "20");
      // dart only reaches for exponent notation well below this, so a trocador minimum
      // stays in plain decimal form and Money.parse can read it
      expect(converter.fromJson(6.4e-05), "0.000064");
    });

    test("passes a string through untouched", () {
      expect(converter.fromJson("1.7835711"), "1.7835711");
      expect(converter.fromJson("0"), "0");
    });

    test("whatever it returns is parseable as a double", () {
      for (final input in <Object>[0.01, 20, "1.78", 6.4e-05]) {
        expect(double.tryParse(converter.fromJson(input)), isNotNull);
      }
    });

    test("writes the string back", () {
      expect(converter.toJson("0.01"), "0.01");
    });
  });
}
