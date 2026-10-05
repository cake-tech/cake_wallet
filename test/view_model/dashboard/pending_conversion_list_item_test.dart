import "package:cake_wallet/entities/pending_conversion.dart";
import "package:cake_wallet/view_model/dashboard/pending_conversion_list_item.dart";
import "package:cake_wallet/entities/conversion_status.dart";
import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  PendingConversionListItem item({
    String amountOutBaseUnits = "2500000",
    int amountOutDecimals = 6,
    String toTicker = "USDB",
    bool toIsToken = true,
  }) =>
      PendingConversionListItem(
        key: const ValueKey("test"),
        conversion: PendingConversion(
          paymentId: "payment-1",
          walletId: "wallet-1",
          fromTicker: "BTC",
          toTicker: toTicker,
          toIsToken: toIsToken,
          amountOutBaseUnits: amountOutBaseUnits,
          amountOutDecimals: amountOutDecimals,
          createdAt: DateTime(2026),
        ),
      );

  group("PendingConversionListItem.formattedAmount", () {
    test("trims trailing fractional zeros", () {
      expect(item(amountOutBaseUnits: "2500000", amountOutDecimals: 6).formattedAmount, "2.5");
    });

    test("keeps a whole number with no decimal point when the fraction is all zeros", () {
      expect(item(amountOutBaseUnits: "3000000", amountOutDecimals: 6).formattedAmount, "3");
    });

    test("keeps significant trailing digits", () {
      expect(item(amountOutBaseUnits: "1234567", amountOutDecimals: 6).formattedAmount, "1.234567");
    });

    test("handles zero decimals", () {
      expect(item(amountOutBaseUnits: "42", amountOutDecimals: 0).formattedAmount, "42");
    });

    test("pads a fraction shorter than decimals before trimming", () {
      expect(item(amountOutBaseUnits: "100", amountOutDecimals: 6).formattedAmount, "0.0001");
    });
  });

  group("PendingConversionListItem.display", () {
    test("is always pending, using the conversion's own from/to tags", () {
      final display = item(toTicker: "USDB", toIsToken: true).display;

      expect(display.status, ConversionStatus.pending);
      expect(display.toLabel, "USDB");
      expect(display.fromLabel, "Lightning");
    });

    test("reflects a token -> BTC conversion", () {
      final display = item(toTicker: "BTC", toIsToken: false).display;

      expect(display.toLabel, "Lightning");
      expect(display.fromLabel, "BTC");
    });
  });
}
