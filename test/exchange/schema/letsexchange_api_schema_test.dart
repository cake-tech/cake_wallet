import "package:cake_wallet/exchange/provider/letsexchange/letsexchange_api_schema.dart";
import "package:cake_wallet/exchange/trade_state.dart";
import "package:flutter_test/flutter_test.dart";

import "../fixture.dart";

void main() {
  group("LetsExchangeInfoResponse", () {
    test("parses info field by field", () {
      final raw = fixtureMap("letsexchange", "info");
      final info = LetsExchangeInfoResponse.fromJson(raw);

      expect(info.minAmount, raw["min_amount"]);
      expect(info.maxAmount, raw["max_amount"]);
      expect(info.amount, raw["amount"]);
      expect(info.fee, raw["fee"]);
      expect(info.rate, raw["rate"]);
      expect(info.profit, raw["profit"]);
      expect(info.withdrawalFee, raw["withdrawal_fee"]);
      expect(info.rateId, raw["rate_id"]);
      expect(info.rateIdExpiredAt, raw["rate_id_expired_at"].toString());
    });

    test("parses info_revert, the fixed rate variant", () {
      final raw = fixtureMap("letsexchange", "info_revert");
      final info = LetsExchangeInfoResponse.fromJson(raw);

      expect(info.minAmount, raw["min_amount"]);
      expect(info.maxAmount, raw["max_amount"]);
      expect(info.amount, raw["amount"]);
      expect(info.rate, raw["rate"]);
      expect(info.rateId, raw["rate_id"]);
      expect(info.rateIdExpiredAt, raw["rate_id_expired_at"].toString());
      expect(info.rateId, isNotEmpty, reason: "a fixed rate quote carries a rate id");
    });

    test("rate_id_expired_at is a number on info and a string on info_revert", () {
      expect(fixtureMap("letsexchange", "info")["rate_id_expired_at"], isA<num>());
      expect(fixtureMap("letsexchange", "info_revert")["rate_id_expired_at"], isA<String>());
    });

    test("the floating quote has no rate id, so nothing to pass to the create call", () {
      final info = LetsExchangeInfoResponse.fromJson(fixtureMap("letsexchange", "info"));

      expect(info.rateId, isEmpty);
    });

    test("the limits parse as amounts", () {
      final info = LetsExchangeInfoResponse.fromJson(fixtureMap("letsexchange", "info"));

      expect(double.tryParse(info.minAmount), isNotNull);
      expect(double.tryParse(info.maxAmount), isNotNull);
      expect(double.tryParse(info.amount), isNotNull);
    });

    test("a rejected info answers with a validation body that this class cannot read", () {
      final raw = fixtureMap("letsexchange", "info_bad_request");

      expect(raw["success"], isFalse);
      expect(raw["error"]["validation"], isNotNull);
      // there is no error class for this api, so the status code has to be checked first
      expect(() => LetsExchangeInfoResponse.fromJson(raw), throwsA(anything));
    });
  });

  group("LetsExchangeTransactionResponse", () {
    for (final name in ["transaction", "create_transaction"]) {
      test("parses $name field by field", () {
        final raw = fixtureMap("letsexchange", name);
        final tx = LetsExchangeTransactionResponse.fromJson(raw);

        expect(tx.transactionId, raw["transaction_id"]);
        expect(tx.coinFrom, raw["coin_from"]);
        expect(tx.coinFromName, raw["coin_from_name"]);
        expect(tx.coinFromNetwork, raw["coin_from_network"]);
        expect(tx.coinTo, raw["coin_to"]);
        expect(tx.coinToName, raw["coin_to_name"]);
        expect(tx.coinToNetwork, raw["coin_to_network"]);
        expect(tx.depositAmount, raw["deposit_amount"]);
        expect(tx.withdrawalAmount, raw["withdrawal_amount"]);
        expect(tx.realDepositAmount, raw["real_deposit_amount"]);
        expect(tx.realWithdrawalAmount, raw["real_withdrawal_amount"]);
        expect(tx.deposit, raw["deposit"]);
        expect(tx.depositExtraId, raw["deposit_extra_id"]);
        expect(tx.withdrawal, raw["withdrawal"]);
        expect(tx.withdrawalExtraId, raw["withdrawal_extra_id"]);
        expect(tx.rate, raw["rate"]);
        expect(tx.fee, raw["fee"]);
        expect(tx.hashIn, raw["hash_in"]);
        expect(tx.hashOut, raw["hash_out"]);
        expect(tx.returnAddress, raw["return"]);
        expect(tx.returnHash, raw["return_hash"]);
        expect(tx.returnAmount, raw["return_amount"]);
        expect(tx.returnExtraId, raw["return_extra_id"]);
        expect(tx.coinFromExplorerUrl, raw["coin_from_explorer_url"]);
        expect(tx.coinToExplorerUrl, raw["coin_to_explorer_url"]);
        expect(tx.needConfirmations, raw["need_confirmations"]);
        expect(tx.confirmations, raw["confirmations"]);
        expect(tx.status, TradeState.deserialize(raw: raw["status"] as String));
        expect(tx.isFloat, const SafeBoolConverter().fromJson(raw["is_float"] as Object));
        expect(tx.createdAt, DateTime.parse(raw["created_at"] as String));
        expect(
          tx.expiredAt,
          DateTime.fromMillisecondsSinceEpoch((raw["expired_at"] as int) * 1000),
          reason: "expired_at is unix seconds on a transaction",
        );
        expect(tx.amlErrorSignals, isEmpty);
      });
    }

    test("is_float is 1 on one endpoint and true on the other", () {
      final onTransaction = fixtureMap("letsexchange", "transaction")["is_float"];
      final onCreate = fixtureMap("letsexchange", "create_transaction")["is_float"];

      expect([onTransaction, onCreate].map((v) => v.runtimeType).toSet(), hasLength(2));
      expect(
        LetsExchangeTransactionResponse.fromJson(
          fixtureMap("letsexchange", "transaction"),
        ).isFloat,
        LetsExchangeTransactionResponse.fromJson(
          fixtureMap("letsexchange", "create_transaction"),
        ).isFloat,
        reason: "both mean the same thing once SafeBoolConverter has had a look",
      );
    });

    test("created_at is space separated rather than iso, and still parses", () {
      final raw = fixtureMap("letsexchange", "transaction");

      expect(raw["created_at"], isNot(contains("T")));
      expect(
        LetsExchangeTransactionResponse.fromJson(raw).createdAt,
        DateTime.parse(raw["created_at"] as String),
      );
    });

    test("the transaction fixture is the one the create fixture made", () {
      final created = LetsExchangeTransactionResponse.fromJson(
        fixtureMap("letsexchange", "create_transaction"),
      );
      final fetched = LetsExchangeTransactionResponse.fromJson(
        fixtureMap("letsexchange", "transaction"),
      );

      expect(fetched.transactionId, created.transactionId);
      expect(fetched.deposit, created.deposit);
    });

    test("the status maps to a wait state", () {
      final tx = LetsExchangeTransactionResponse.fromJson(
        fixtureMap("letsexchange", "transaction"),
      );

      expect(tx.status, TradeState.wait);
    });
  });

  group("requests", () {
    test("LetsExchangeInfoRequest serializes the snake case keys", () {
      final json = const LetsExchangeInfoRequest(
        from: "BTC",
        to: "XMR",
        amount: "1",
        affiliateId: "affiliate",
        float: true,
      ).toJson();

      expect(json, {
        "from": "BTC",
        "to": "XMR",
        "amount": "1",
        "affiliate_id": "affiliate",
        "float": true,
      });
    });

    test("LetsExchangeInfoRequest carries the networks when there are any", () {
      final json = const LetsExchangeInfoRequest(
        from: "USDT",
        to: "USDC",
        networkFrom: "ERC20",
        networkTo: "ERC20",
        amount: "150",
        affiliateId: "affiliate",
        float: false,
      ).toJson();

      expect(json["network_from"], "ERC20");
      expect(json["network_to"], "ERC20");
      expect(json["float"], isFalse);
      expect(json.containsKey("promocode"), isFalse);
      expect(json.containsKey("partner_user_ip"), isFalse);
    });

    test("LetsExchangeCreateTransactionRequest serializes the transaction parameters", () {
      final json = const LetsExchangeCreateTransactionRequest(
        coinFrom: "USDT",
        coinTo: "USDC",
        withdrawal: "0xpayout",
        withdrawalExtraId: "",
        affiliateId: "affiliate",
        float: true,
        networkFrom: "ERC20",
        networkTo: "ERC20",
        depositAmount: "150",
        returnAddress: "0xrefund",
        rateId: "rate-id",
      ).toJson();

      expect(json["coin_from"], "USDT");
      expect(json["coin_to"], "USDC");
      expect(json["network_from"], "ERC20");
      expect(json["deposit_amount"], "150");
      expect(json["withdrawal"], "0xpayout");
      expect(json["withdrawal_extra_id"], "");
      expect(json["return"], "0xrefund", reason: "the refund key is return, a dart keyword");
      expect(json["rate_id"], "rate-id");
      expect(json["affiliate_id"], "affiliate");
      expect(json["float"], isTrue);
      expect(json.containsKey("withdrawal_amount"), isFalse);
      expect(json.containsKey("email"), isFalse);
    });
  });

  group("SafeBoolConverter", () {
    const converter = SafeBoolConverter();

    test("takes a real boolean, which is what the fixtures carry", () {
      expect(converter.fromJson(true), isTrue);
      expect(converter.fromJson(false), isFalse);
    });

    test("takes the string form the docs show", () {
      expect(converter.fromJson("true"), isTrue);
      expect(converter.fromJson("True"), isTrue);
      expect(converter.fromJson("false"), isFalse);
    });

    test("takes the 1 and 0 form a curl showed", () {
      expect(converter.fromJson(1), isTrue);
      expect(converter.fromJson(0), isFalse);
    });

    test("writes the value back", () {
      expect(converter.toJson(true), true);
    });
  });

  group("SafeStringConverter", () {
    const converter = SafeStringConverter();

    test("stringifies whichever form rate_id_expired_at arrives in", () {
      expect(converter.fromJson(0), "0");
      expect(converter.fromJson("1785333936912"), "1785333936912");
      expect(converter.fromJson(1785333936912), "1785333936912");
    });

    test("writes the string back", () {
      expect(converter.toJson("0"), "0");
    });
  });
}
