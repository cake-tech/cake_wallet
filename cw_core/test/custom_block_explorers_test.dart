import "package:cw_core/custom_block_explorers.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("explorers", () {
    test("accepts plain addresses and {txid} templates", () {
      expect(CustomBlockExplorers.isValidExplorer("https://explorer.example.com"), isTrue);
      expect(CustomBlockExplorers.isValidExplorer("http://abc.onion/"), isTrue);
      expect(CustomBlockExplorers.isValidExplorer("https://example.com/xmr"), isTrue);
      expect(CustomBlockExplorers.isValidExplorer("https://mempool.example/tx/{txid}"), isTrue);
      expect(CustomBlockExplorers.isValidExplorer("http://dcr.example:7777/t?id={txid}"), isTrue);
    });

    test("rejects missing hosts, other schemes, and query strings without {txid}", () {
      expect(CustomBlockExplorers.isValidExplorer("explorer.example.com"), isFalse);
      expect(CustomBlockExplorers.isValidExplorer("ftp://explorer.example.com"), isFalse);
      expect(CustomBlockExplorers.isValidExplorer("javascript:alert({txid})"), isFalse);
      expect(CustomBlockExplorers.isValidExplorer("https://explorer.example.com/?a=1"), isFalse);
      expect(CustomBlockExplorers.isValidExplorer(""), isFalse);
    });

    test("buildTxUrl appends /tx/<id> to an address", () {
      expect(
          CustomBlockExplorers.buildTxUrl(" http://x.onion/ ", "ab12"), "http://x.onion/tx/ab12");
      expect(CustomBlockExplorers.buildTxUrl("https://example.com/xmr", "ab12"),
          "https://example.com/xmr/tx/ab12");
    });

    test("buildTxUrl fills every {txid} in a template and ignores bad input", () {
      expect(
        CustomBlockExplorers.buildTxUrl("http://x.onion/t?id={txid}#{txid}", "ab12"),
        "http://x.onion/t?id=ab12#ab12",
      );
      expect(CustomBlockExplorers.buildTxUrl("explorer.example.com", "ab12"), isNull);
      expect(CustomBlockExplorers.buildTxUrl(null, "ab12"), isNull);
    });
  });

  group("mempool base URL", () {
    test("normalizes trailing slashes and pasted /api paths", () {
      expect(CustomBlockExplorers.normalizeBaseUrl(" http://x.onion/ "), "http://x.onion");
      expect(CustomBlockExplorers.normalizeBaseUrl("http://x.onion/api/v1/"), "http://x.onion");
      expect(CustomBlockExplorers.normalizeBaseUrl("https://m.example/mempool/api"),
          "https://m.example/mempool");
    });

    test("validates", () {
      expect(CustomBlockExplorers.isValidBaseUrl("http://x.onion"), isTrue);
      expect(CustomBlockExplorers.isValidBaseUrl("https://m.example/mempool/"), isTrue);
      expect(CustomBlockExplorers.isValidBaseUrl("m.example"), isFalse);
      expect(CustomBlockExplorers.isValidBaseUrl("https://m.example/?a=1"), isFalse);
      expect(CustomBlockExplorers.isValidBaseUrl("https://m.example/tx/{txid}"), isFalse);
    });

    test("uses the default server when nothing valid is configured", () {
      for (final base in [null, "", "  ", "not a url"]) {
        final uris = CustomBlockExplorers.mempoolApiUris(base, "/api/v1/fees/recommended");
        expect(uris.clearnet.toString(), "https://mempool.cakewallet.com/api/v1/fees/recommended");
        expect(uris.onion, isNull);
      }

      final withOnion = CustomBlockExplorers.mempoolApiUris(null, "/api/v1/fees/recommended",
          withDefaultOnion: true);
      expect(withOnion.onion.toString(),
          "${CustomBlockExplorers.defaultMempoolApiOnion}/api/v1/fees/recommended");
    });

    test("uses only the custom server, as onion or clearnet by its host", () {
      final onion = CustomBlockExplorers.mempoolApiUris("http://x.onion/", "/api/v1/block/h",
          withDefaultOnion: true);
      expect(onion.onion.toString(), "http://x.onion/api/v1/block/h");
      expect(onion.clearnet, isNull);

      final clearnet = CustomBlockExplorers.mempoolApiUris(
          "https://m.example/api", "/api/v1/block/h",
          withDefaultOnion: true);
      expect(clearnet.clearnet.toString(), "https://m.example/api/v1/block/h");
      expect(clearnet.onion, isNull);
    });
  });
}
