import "package:cake_wallet/exchange/rate_request.dart";
import "package:cake_wallet/exchange/trade_request.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  final twoBtc = Money.parse("2", CryptoCurrency.btc);
  final fiveHundredXmr = Money.parse("500", CryptoCurrency.xmr);

  group("FloatingRateRequest", () {
    test("the deposit amount fixes the deposit side", () {
      final request = FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr);

      expect(request.depositCurrency, CryptoCurrency.btc);
      expect(request.payoutCurrency, CryptoCurrency.xmr);
      expect(request.amount, twoBtc);
    });
  });

  group("FixedRateRequest", () {
    test("the payout amount fixes the payout side", () {
      final request = FixedRateRequest(depositCurrency: CryptoCurrency.btc, payoutAmount: fiveHundredXmr);

      expect(request.depositCurrency, CryptoCurrency.btc);
      expect(request.payoutCurrency, CryptoCurrency.xmr);
      expect(request.amount, fiveHundredXmr);
    });
  });

  group("isSameQuery", () {
    test("the same pair and kind is the same query whatever the amount", () {
      expect(
        FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr).isSameQuery(
          FloatingRateRequest(
            depositAmount: Money.parse("0.5", CryptoCurrency.btc),
            payoutCurrency: CryptoCurrency.xmr,
          ),
        ),
        isTrue,
      );
      expect(
        FixedRateRequest(depositCurrency: CryptoCurrency.btc, payoutAmount: fiveHundredXmr).isSameQuery(
          FixedRateRequest(
            depositCurrency: CryptoCurrency.btc,
            payoutAmount: Money.parse("1", CryptoCurrency.xmr),
          ),
        ),
        isTrue,
      );
    });

    test("floating and fixed rates for the same pair are different queries", () {
      final floating = FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr);
      final fixed = FixedRateRequest(depositCurrency: CryptoCurrency.btc, payoutAmount: fiveHundredXmr);

      expect(floating.isSameQuery(fixed), isFalse);
      expect(fixed.isSameQuery(floating), isFalse);
    });

    test("a different deposit or payout currency is a different query", () {
      final request = FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr);

      expect(
        request.isSameQuery(
          FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.eth),
        ),
        isFalse,
      );
      expect(
        request.isSameQuery(
          FloatingRateRequest(
            depositAmount: Money.parse("2", CryptoCurrency.ltc),
            payoutCurrency: CryptoCurrency.xmr,
          ),
        ),
        isFalse,
      );
    });

    test("the reversed pair is a different query", () {
      expect(
        FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr).isSameQuery(
          FloatingRateRequest(depositAmount: fiveHundredXmr, payoutCurrency: CryptoCurrency.btc),
        ),
        isFalse,
      );
    });
  });

  group("equality", () {
    test("the same query for the same amount is equal", () {
      final request = FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr);
      final same = FloatingRateRequest(
        depositAmount: Money.parse("2.0", CryptoCurrency.btc),
        payoutCurrency: CryptoCurrency.xmr,
      );

      expect(request, same);
      expect(request.hashCode, same.hashCode);
    });

    test("the same query for a different amount is not equal", () {
      expect(
        FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr),
        isNot(
          FloatingRateRequest(
            depositAmount: Money.parse("0.5", CryptoCurrency.btc),
            payoutCurrency: CryptoCurrency.xmr,
          ),
        ),
      );
      expect(
        FixedRateRequest(depositCurrency: CryptoCurrency.btc, payoutAmount: fiveHundredXmr),
        isNot(
          FixedRateRequest(
            depositCurrency: CryptoCurrency.btc,
            payoutAmount: Money.parse("1", CryptoCurrency.xmr),
          ),
        ),
      );
    });

    test("floating and fixed requests are never equal", () {
      expect(
        FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.btc),
        isNot(FixedRateRequest(depositCurrency: CryptoCurrency.btc, payoutAmount: twoBtc)),
      );
    });
  });

  group("toJson", () {
    test("a floating request logs the deposit amount", () {
      expect(
        FloatingRateRequest(depositAmount: twoBtc, payoutCurrency: CryptoCurrency.xmr).toJson(),
        {
          "depositCurrency": CryptoCurrency.btc.serialized,
          "payoutCurrency": CryptoCurrency.xmr.serialized,
          "amount": twoBtc.serialized,
          "isFixedRate": false,
        },
      );
    });

    test("a fixed request logs the payout amount", () {
      expect(
        FixedRateRequest(depositCurrency: CryptoCurrency.btc, payoutAmount: fiveHundredXmr).toJson(),
        {
          "depositCurrency": CryptoCurrency.btc.serialized,
          "payoutCurrency": CryptoCurrency.xmr.serialized,
          "amount": fiveHundredXmr.serialized,
          "isFixedRate": true,
        },
      );
    });
  });

  group("TradeRequest.rateRequest", () {
    TradeRequest tradeRequest({required bool isFixedRate}) => TradeRequest(
      refundAddress: "refund-address",
      payoutAddress: "payout-address",
      depositAmount: twoBtc,
      payoutAmount: fiveHundredXmr,
      isFixedRate: isFixedRate,
    );

    test("a floating trade re-quotes its deposit amount", () {
      final request = tradeRequest(isFixedRate: false).rateRequest;

      expect(request, isA<FloatingRateRequest>());
      expect((request as FloatingRateRequest).depositAmount, twoBtc);
      expect(request.payoutCurrency, CryptoCurrency.xmr);
    });

    test("a fixed trade re-quotes its payout amount", () {
      final request = tradeRequest(isFixedRate: true).rateRequest;

      expect(request, isA<FixedRateRequest>());
      expect((request as FixedRateRequest).payoutAmount, fiveHundredXmr);
      expect(request.depositCurrency, CryptoCurrency.btc);
    });
  });

  group("TradeRequest", () {
    test("an empty extra id is dropped, since providers reject it", () {
      final request = TradeRequest(
        refundAddress: "refund-address",
        payoutAddress: "payout-address",
        depositAmount: twoBtc,
        payoutAmount: fiveHundredXmr,
        isFixedRate: false,
        toAddressExtraId: "",
      );

      expect(request.toAddressExtraId, isNull);
    });

    test("a real extra id is kept", () {
      final request = TradeRequest(
        refundAddress: "refund-address",
        payoutAddress: "payout-address",
        depositAmount: twoBtc,
        payoutAmount: fiveHundredXmr,
        isFixedRate: false,
        toAddressExtraId: "memo",
      );

      expect(request.toAddressExtraId, "memo");
    });
  });
}
