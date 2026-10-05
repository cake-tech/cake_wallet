import "package:cake_wallet/entities/conversion_display.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ConversionDisplayUtils.needsAttention", () {
    test("failed and refundNeeded need attention", () {
      expect(ConversionDisplayUtils.needsAttention(ConversionStatus.failed), isTrue);
      expect(ConversionDisplayUtils.needsAttention(ConversionStatus.refundNeeded), isTrue);
    });

    test("pending, completed, and refunded don't need attention", () {
      expect(ConversionDisplayUtils.needsAttention(ConversionStatus.pending), isFalse);
      expect(ConversionDisplayUtils.needsAttention(ConversionStatus.completed), isFalse);
      expect(ConversionDisplayUtils.needsAttention(ConversionStatus.refunded), isFalse);
    });
  });

  group("ConversionDisplayUtils.displayFrom", () {
    Map<String, dynamic> infoFor(
      ConversionStatus status, {
      required String from,
      required String to,
      required bool toIsToken,
    }) =>
        {
          "conversionStatus": status.name,
          "conversionFromTicker": from,
          "conversionToTicker": to,
          "conversionToIsToken": toIsToken,
        };

    for (final status in ConversionStatus.values) {
      test("BTC -> token ($status): toLabel is the token, fromLabel is Lightning", () {
        final display = ConversionDisplayUtils.displayFrom(
          infoFor(status, from: "BTC", to: "USDB", toIsToken: true),
        );

        expect(display, isNotNull);
        expect(display!.status, status);
        expect(display.toLabel, "USDB");
        expect(display.fromLabel, "Lightning");
      });

      test("token -> BTC ($status): toLabel is Lightning, fromLabel is the token", () {
        final display = ConversionDisplayUtils.displayFrom(
          infoFor(status, from: "USDB", to: "BTC", toIsToken: false),
        );

        expect(display, isNotNull);
        expect(display!.status, status);
        expect(display.toLabel, "Lightning");
        expect(display.fromLabel, "USDB");
      });
    }

    test("returns null when the payment isn't a conversion at all", () {
      expect(ConversionDisplayUtils.displayFrom({"isLightning": true}), isNull);
    });

    test("returns null for an older stored transaction missing the asset tags", () {
      expect(
        ConversionDisplayUtils.displayFrom({"conversionStatus": ConversionStatus.completed.name}),
        isNull,
      );
    });

    test("returns null when a tag has the wrong type", () {
      expect(
        ConversionDisplayUtils.displayFrom({
          "conversionStatus": ConversionStatus.pending.name,
          "conversionFromTicker": "BTC",
          "conversionToTicker": "USDB",
          "conversionToIsToken": "true", // string, not bool
        }),
        isNull,
      );
    });

    test("formats the conversion steps and amount adjustment when the SDK reported them", () {
      final display = ConversionDisplayUtils.displayFrom({
        "conversionStatus": "completed",
        "conversionFromTicker": "USDB",
        "conversionToTicker": "BTC",
        "conversionToIsToken": false,
        "conversionFromAmount": "2996770",
        "conversionFromFee": "0",
        "conversionFromDecimals": 6,
        "conversionToAmount": "3569",
        "conversionToFee": "12",
        "conversionToDecimals": 8,
        "conversionAmountAdjustment": "increasedToAvoidDust",
      })!;

      expect(display.fromAmount, "2.99677 USDB");
      expect(display.fromFee, isNull, reason: "a zero fee isn't worth showing");
      expect(display.toAmount, "3569 sats");
      expect(display.toFee, "12 sats");
      expect(display.amountAdjustment, ConversionAmountAdjustment.increasedToAvoidDust);
    });

    test("leaves the step amounts null while a leg is still in flight", () {
      final display = ConversionDisplayUtils.displayFrom({
        "conversionStatus": "pending",
        "conversionFromTicker": "BTC",
        "conversionToTicker": "USDB",
        "conversionToIsToken": true,
      })!;

      expect(display.fromAmount, isNull);
      expect(display.toAmount, isNull);
      expect(display.amountAdjustment, isNull);
    });
  });
}
