import "package:cake_wallet/core/address_resolver/lnurl_pay/lnurlpay_record.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("LNUrlPayRecord.wellKnownUrl", () {
    test("builds the pay request url of a Lightning username", () {
      expect(
        LNUrlPayRecord.wellKnownUrl("Konsti@cake.cash"),
        "https://cake.cash/.well-known/lnurlp/konsti",
      );
    });

    test("reads a username written with a leading @", () {
      expect(
        LNUrlPayRecord.wellKnownUrl("@alice@domain.org"),
        "https://domain.org/.well-known/lnurlp/alice",
      );
    });

    test("uses _ for a username without a name", () {
      expect(LNUrlPayRecord.wellKnownUrl("@domain.org"), "https://domain.org/.well-known/lnurlp/_");
    });
  });
}
