import "package:cake_wallet/exchange/provider/exolix/exolix_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("ExolixRateResponse", () {
    for (final name in ["rate", "rate_fixed"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("exolix", name);
        final rate = ExolixRateResponse.fromJson(raw);

        expect(rate.fromAmount, (raw["fromAmount"] as num).toDouble());
        expect(rate.toAmount, (raw["toAmount"] as num).toDouble());
        expect(rate.rate, (raw["rate"] as num).toDouble());
        expect(rate.message, raw["message"]);
        expect(rate.minAmount, raw["minAmount"]);
        expect(rate.withdrawMin, raw["withdrawMin"]);
        expect(rate.maxAmount, raw["maxAmount"]);
      });
    }

    test("the fixed rate is quoted lower than the floating one", () {
      final floating = ExolixRateResponse.fromJson(fixtureMap("exolix", "rate"));
      final fixed = ExolixRateResponse.fromJson(fixtureMap("exolix", "rate_fixed"));

      expect(floating.rate, isNotNull);
      expect(fixed.rate, isNotNull);
      expect(fixed.rate! <= floating.rate!, isTrue);
    });

    test("below the minimum, the body drops the rate and explains itself", () {
      final raw = fixtureMap("exolix", "rate_below_min");
      final rate = ExolixRateResponse.fromJson(raw);

      expect(raw.containsKey("rate"), isFalse, reason: "which is why rate has to be nullable");
      expect(rate.rate, isNull);
      expect(rate.toAmount, 0);
      expect(rate.message, raw["message"]);
      expect(rate.minAmount, raw["minAmount"]);
      expect(rate.maxAmount, raw["maxAmount"]);
      expect(rate.withdrawMin, isNull);
    });
  });

  group("ExolixTransactionResponse", () {
    for (final name in ["transaction", "create_transaction"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("exolix", name);
        final tx = ExolixTransactionResponse.fromJson(raw);

        expect(tx.id, raw["id"]);
        expect(tx.amount, (raw["amount"] as num).toDouble());
        expect(tx.amountTo, raw["amountTo"]);
        expect(tx.comment, raw["comment"]);
        expect(tx.createdAt, DateTime.parse(raw["createdAt"] as String));
        expect(tx.depositAddress, raw["depositAddress"]);
        expect(tx.depositExtraId, raw["depositExtraId"]);
        expect(tx.withdrawalAddress, raw["withdrawalAddress"]);
        expect(tx.withdrawalExtraId, raw["withdrawalExtraId"]);
        expect(tx.refundAddress, raw["refundAddress"]);
        expect(tx.refundExtraId, raw["refundExtraId"]);
        expect(tx.rate, (raw["rate"] as num).toDouble());
        expect(tx.rateType, ExolixRateType.float);
        expect(tx.status, TradeState.deserialize(raw: raw["status"] as String));

        expect(tx.coinFrom.coinCode, raw["coinFrom"]["coinCode"]);
        expect(tx.coinFrom.coinName, raw["coinFrom"]["coinName"]);
        expect(tx.coinFrom.network, raw["coinFrom"]["network"]);
        expect(tx.coinFrom.networkName, raw["coinFrom"]["networkName"]);
        expect(tx.coinFrom.networkShortName, raw["coinFrom"]["networkShortName"]);
        expect(tx.coinFrom.icon, raw["coinFrom"]["icon"]);
        expect(tx.coinFrom.memoName, raw["coinFrom"]["memoName"]);
        expect(tx.coinFrom.contract, raw["coinFrom"]["contract"]);

        expect(tx.coinTo.coinCode, raw["coinTo"]["coinCode"]);
        expect(tx.coinTo.network, raw["coinTo"]["network"]);
        expect(tx.hashIn.hash, raw["hashIn"]["hash"]);
        expect(tx.hashIn.link, raw["hashIn"]["link"]);
        expect(tx.hashOut.hash, raw["hashOut"]["hash"]);
        expect(tx.hashOut.link, raw["hashOut"]["link"]);
      });
    }

    test("the transaction fixture is the one the create fixture made", () {
      final created = ExolixTransactionResponse.fromJson(
        fixtureMap("exolix", "create_transaction"),
      );
      final fetched = ExolixTransactionResponse.fromJson(fixtureMap("exolix", "transaction"));

      expect(fetched.id, created.id);
      expect(fetched.depositAddress, created.depositAddress);
    });

    test("no deposit has landed, so both hashes are empty", () {
      final tx = ExolixTransactionResponse.fromJson(fixtureMap("exolix", "transaction"));

      expect(tx.hashIn.hash, isNull);
      expect(tx.hashOut.hash, isNull);
    });
  });

  group("requests", () {
    test("ExolixRateRequest serializes the rate type as its wire value", () {
      final json = const ExolixRateRequest(
        coinFrom: "BTC",
        coinTo: "XMR",
        networkFrom: "BTC",
        networkTo: "XMR",
        rateType: ExolixRateType.float,
        amount: "1",
        apiToken: "token",
      ).toJson();

      expect(json, {
        "coinFrom": "BTC",
        "coinTo": "XMR",
        "networkFrom": "BTC",
        "networkTo": "XMR",
        "rateType": "float",
        "amount": "1",
        "apiToken": "token",
      });
    });

    test("ExolixRateRequest writes fixed for a fixed rate and drops the unused amount", () {
      final json = const ExolixRateRequest(
        coinFrom: "BTC",
        coinTo: "XMR",
        networkFrom: "BTC",
        networkTo: "XMR",
        rateType: ExolixRateType.fixed,
        withdrawalAmount: "1",
        apiToken: "token",
      ).toJson();

      expect(json["rateType"], "fixed");
      expect(json["withdrawalAmount"], "1");
      expect(json.containsKey("amount"), isFalse);
    });

    test("every value in a rate request is a string, which Uri.https needs", () {
      final json = const ExolixRateRequest(
        coinFrom: "BTC",
        coinTo: "XMR",
        networkFrom: "BTC",
        networkTo: "XMR",
        rateType: ExolixRateType.float,
        amount: "1",
        apiToken: "token",
      ).toJson();

      expect(json.values.whereType<String>(), hasLength(json.length));
    });

    test("ExolixCreateTransactionRequest serializes the transaction parameters", () {
      final json = const ExolixCreateTransactionRequest(
        coinFrom: "ETH",
        coinTo: "USDT",
        networkFrom: "ETH",
        networkTo: "ETH",
        withdrawalAddress: "0xpayout",
        rateType: ExolixRateType.float,
        amount: "0.01",
        refundAddress: "0xrefund",
        apiToken: "token",
      ).toJson();

      expect(json["coinFrom"], "ETH");
      expect(json["withdrawalAddress"], "0xpayout");
      expect(json["refundAddress"], "0xrefund");
      expect(json["rateType"], "float");
      expect(json["amount"], "0.01");
      expect(json["apiToken"], "token");
      expect(json.containsKey("withdrawalAmount"), isFalse);
      expect(json.containsKey("withdrawalExtraId"), isFalse);
      expect(json.containsKey("slippage"), isFalse);
    });
  });
}
