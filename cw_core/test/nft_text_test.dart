import "package:cw_core/utils/nft_text.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("sanitizeNFTText", () {
    test("removes the separators that would fake extra lines", () {
      expect(sanitizeNFTText("Ape\u2028Address: 9xQeW"), "Ape Address: 9xQeW");
      expect(sanitizeNFTText("Ape\u2029Address: 9xQeW"), "Ape Address: 9xQeW");
      expect(sanitizeNFTText("Ape\nAddress: 9xQeW"), "Ape Address: 9xQeW");
    });

    test("removes bidi overrides and isolates that reorder what follows", () {
      expect(sanitizeNFTText("evil\u202Etxen"), "evil txen");
      expect(sanitizeNFTText("a\u2066b\u2069c"), "a b c");
    });

    test("removes invisibles that hide or reorder characters", () {
      expect(sanitizeNFTText("A\u200BB"), "A B");
      expect(sanitizeNFTText("A\u200FB"), "A B");
      expect(sanitizeNFTText("A\u061CB"), "A B");
      expect(sanitizeNFTText("A\u2060B"), "A B");
    });

    test("removes control characters and delete", () {
      expect(sanitizeNFTText("A\u0000B"), "A B");
      expect(sanitizeNFTText("A\u001FB"), "A B");
      expect(sanitizeNFTText("A\u007FB"), "A B");
    });

    test("leaves ordinary text alone", () {
      expect(sanitizeNFTText("DeGod #1234"), "DeGod #1234");
      expect(sanitizeNFTText("  padded  "), "padded");
    });

    test("returns null for null", () {
      expect(sanitizeNFTText(null), isNull);
    });

    test("counts the cap in characters, so emoji are not cut in half", () {
      final long = sanitizeNFTText("\u{1F600}" * 600)!;

      expect(long.runes.length, 513);
      expect(long.runes.last, 0x2026);

      final units = long.codeUnits;
      final endsOnHighSurrogate = units.isNotEmpty && units.last >= 0xD800 && units.last <= 0xDBFF;
      expect(endsOnHighSurrogate, isFalse);
    });

    test("does not truncate a name that is long in code units but short in characters", () {
      expect(sanitizeNFTText("\u{1F600}" * 400)!.runes.length, 400);
    });

    test("is idempotent, so re-reading a saved value does not change it", () {
      const raw = "Ape\u2028Name\u202E with \u{1F600}";
      final once = sanitizeNFTText(raw);

      expect(sanitizeNFTText(once), once);
    });

    test("keeps the joiners that carry meaning in persian and emoji", () {
      // Replacing these put a visible space inside a Persian word and split
      // a two-person emoji into two glyphs.
      expect(sanitizeNFTText("\u{1F468}\u200D\u{1F4BB}"), "\u{1F468}\u200D\u{1F4BB}");
      expect(
        sanitizeNFTText("\u0645\u06CC\u200C\u062E\u0648\u0627\u0647\u0645"),
        "\u0645\u06CC\u200C\u062E\u0648\u0627\u0647\u0645",
      );
    });

    test("strips the invisibles a mint can hide text behind", () {
      for (final invisible in [
        "\u00AD", // soft hyphen
        "\u034F", // combining grapheme joiner
        "\u180E", // mongolian vowel separator
        "\u3164", // hangul filler
        "\uFEFF", // zero width no-break space
        "\uFFA0", // halfwidth hangul filler
        "\u{E0041}", // tag latin capital A
      ]) {
        expect(
          sanitizeNFTText("A${invisible}B"),
          "A B",
          reason: "U+${invisible.runes.first.toRadixString(16).toUpperCase()} survived",
        );
      }
    });
  });
}
