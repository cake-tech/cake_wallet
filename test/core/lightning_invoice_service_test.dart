import "package:cake_wallet/core/lightning_invoice_service.dart";
import "package:cw_core/lnurl.dart";
import "package:cw_core/utils/proxy_wrapper.dart";
import "package:cw_core/utils/tor/abstract.dart";
import "package:flutter_test/flutter_test.dart";

Future<void> main() async {
  CakeTor.instance = await CakeTorInstance.getInstance();

  group("lightning_invoice_service", () {
    test("Should resolve an empty Bolt11 invoice konsti@cake.cash", () async {
      final invoice = await getBolt11FromLightingAddress("konsti@cake.cash");

      expect(invoice, isNotNull);
      expect(isBolt11ZeroInvoice(invoice!), isTrue);
    });

    test("Should not resolve an empty Bolt11 invoice viksharma@cluborange.org", () async {
      final invoice = await getBolt11FromLightingAddress("viksharma@cluborange.org");

      expect(invoice, isNull);
    });

    test("Should resolve an Bolt11 invoice viksharma@cluborange.org", () async {
      final invoice =
          await getBolt11FromLightingAddress("viksharma@cluborange.org", amount: 1000000000);

      expect(invoice, isNotNull);
    });
  });
}
