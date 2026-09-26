import "package:cw_core/utils/ipfs_url.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("tryNormalizeIpfsUrl", () {
    test("rewrites an ipfs uri to the gateway", () {
      expect(tryNormalizeIpfsUrl("ipfs://QmAbC123"), "https://ipfs.io/ipfs/QmAbC123");
    });

    test("does not double the gateway path when the uri already says ipfs/", () {
      expect(tryNormalizeIpfsUrl("ipfs://ipfs/QmAbC123"), "https://ipfs.io/ipfs/QmAbC123");
    });

    test("matches the scheme whatever its case", () {
      expect(tryNormalizeIpfsUrl("IPFS://QmAbC123"), "https://ipfs.io/ipfs/QmAbC123");
      expect(tryNormalizeIpfsUrl("Ipfs://QmAbC123"), "https://ipfs.io/ipfs/QmAbC123");
    });

    test("returns null for an ipfs uri with no cid, rather than a bare gateway url", () {
      expect(tryNormalizeIpfsUrl("ipfs://"), isNull);
      expect(tryNormalizeIpfsUrl("ipfs://ipfs/"), isNull);
    });

    test("passes through an https url that is not ipfs", () {
      expect(tryNormalizeIpfsUrl("https://arweave.net/abc"), "https://arweave.net/abc");
    });

    test("drops a scheme nothing can render, rather than handing it to the image widget", () {
      expect(tryNormalizeIpfsUrl("ar://abc123"), isNull);
      expect(tryNormalizeIpfsUrl(""), isNull);
    });

    test("returns null for null", () {
      expect(tryNormalizeIpfsUrl(null), isNull);
    });

    test("is idempotent, so a value read back from storage stays stable", () {
      final once = tryNormalizeIpfsUrl("ipfs://QmAbC123");
      expect(tryNormalizeIpfsUrl(once), once);
    });

    test("drops any scheme that is not https", () {
      // These render through Image.network, which does not go through the proxy.
      expect(tryNormalizeIpfsUrl("http://127.0.0.1:8080/x.png"), isNull);
      expect(tryNormalizeIpfsUrl("file:///etc/passwd"), isNull);
      expect(tryNormalizeIpfsUrl("javascript:alert(1)"), isNull);
      expect(tryNormalizeIpfsUrl("data:text/html,x"), isNull);
    });

    test("keeps an https url whatever its casing", () {
      expect(tryNormalizeIpfsUrl("https://ok.example/a.png"), "https://ok.example/a.png");
      expect(tryNormalizeIpfsUrl("HTTPS://Up.example/a.png"), "HTTPS://Up.example/a.png");
    });
  });
}
