import "package:cake_wallet/exchange/trade_state.dart";
import "package:cake_wallet/exchange/utils/json_converters.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("MillisDateTimeConverter", () {
    const converter = MillisDateTimeConverter();

    test("reads milliseconds as utc", () {
      final date = converter.fromJson(1785317668000);

      expect(date.isUtc, isTrue);
      expect(date, DateTime.utc(2026, 7, 29, 9, 34, 28));
    });

    test("round trips", () {
      const millis = 1785317668123;

      expect(converter.toJson(converter.fromJson(millis)), millis);
    });

    test("handles the epoch", () {
      expect(converter.fromJson(0), DateTime.utc(1970));
      expect(converter.toJson(DateTime.utc(1970)), 0);
    });
  });

  group("SecondsDateTimeConverter", () {
    const converter = SecondsDateTimeConverter();

    test("reads seconds, not milliseconds", () {
      expect(converter.fromJson(1785317668).millisecondsSinceEpoch, 1785317668 * 1000);
    });

    test("round trips", () {
      const seconds = 1785317668;

      expect(converter.toJson(converter.fromJson(seconds)), seconds);
    });

    test("drops sub second precision on the way out", () {
      final date = DateTime.fromMillisecondsSinceEpoch(1785317668999);

      expect(converter.toJson(date), 1785317668);
    });
  });

  group("TradeStateConverter", () {
    const converter = TradeStateConverter();

    test("maps the states the providers actually send", () {
      expect(converter.fromJson("waiting"), TradeState.waiting);
      expect(converter.fromJson("confirming"), TradeState.confirming);
      expect(converter.fromJson("exchanging"), TradeState.exchanging);
      expect(converter.fromJson("sending"), TradeState.sending);
      expect(converter.fromJson("finished"), TradeState.finished);
      expect(converter.fromJson("failed"), TradeState.failed);
      expect(converter.fromJson("refunded"), TradeState.refunded);
      expect(converter.fromJson("expired"), TradeState.expired);
      expect(converter.fromJson("success"), TradeState.success);
    });

    test("maps the aliases", () {
      expect(converter.fromJson("inProgress"), TradeState.processing);
      expect(converter.fromJson("error"), TradeState.failed);
      expect(converter.fromJson("done"), TradeState.success);
      expect(converter.fromJson("verifying"), TradeState.confirmation);
      expect(converter.fromJson("sending_confirmation"), TradeState.sending);
    });

    test("keeps an unknown state instead of throwing", () {
      final state = converter.fromJson("brand_new_state");

      expect(state.raw, "brand_new_state");
      expect(state.title, "brand_new_state");
    });

    test("round trips", () {
      expect(converter.toJson(TradeState.waiting), "waiting");
      expect(converter.fromJson(converter.toJson(TradeState.refunded)), TradeState.refunded);
    });
  });

  group("StringBoolConverter", () {
    const converter = StringBoolConverter();

    test("reads the casings a provider might send", () {
      expect(converter.fromJson("true"), isTrue);
      expect(converter.fromJson("True"), isTrue);
      expect(converter.fromJson("TRUE"), isTrue);
      expect(converter.fromJson("false"), isFalse);
      expect(converter.fromJson("False"), isFalse);
    });

    test("anything unrecognised is false", () {
      expect(converter.fromJson(""), isFalse);
      expect(converter.fromJson("1"), isFalse);
      expect(converter.fromJson("yes"), isFalse);
    });

    test("writes lowercase, which is what a query param wants", () {
      expect(converter.toJson(true), "true");
      expect(converter.toJson(false), "false");
    });
  });
}
