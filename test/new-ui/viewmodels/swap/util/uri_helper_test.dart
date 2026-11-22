import "package:cake_wallet/new-ui/viewmodels/swap/util/uri_helper.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/payment_uris.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("tokens on chains without a Cake wallet get no deposit QR", () {
    expect(SwapUriHelper.getUri("deposit-address", "100", CryptoCurrency.usdtTon), isNull);
    expect(
      SwapUriHelper.getUri("deposit-address", "100", CryptoCurrency.xrp),
      isA<ExternalAddressURI>(),
    );
    expect(
      SwapUriHelper.getUri(
        "0x1111111111111111111111111111111111111111",
        "100",
        CryptoCurrency.usdterc20,
      ),
      isA<ERC681URI>(),
    );
  });
}
