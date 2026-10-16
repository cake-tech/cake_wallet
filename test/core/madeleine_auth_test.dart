import "package:cake_wallet/core/madeleine_auth.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;

const _madeleineUrl = "madeleine.cakewallet.com";

void main() {
  group("MadeleineAuth", () {
    test("AuthLight", () async {
      final uri = Uri.https(
        _madeleineUrl,
        "/api/moonpay/payment-methods",
        {"currencyCode": "EUR", "countryCode": "DEU", "transactionType": "buy"},
      );

      final headers = MadeleineAuth(useSandbox: true)
          .getLightHeaders(method: "GET", path: "/api/moonpay/payment-methods");

      final response = await http.get(uri, headers: headers);

      expect(response.statusCode, 200);
    });
  });
}
