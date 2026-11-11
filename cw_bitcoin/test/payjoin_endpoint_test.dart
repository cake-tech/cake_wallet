import "package:cw_bitcoin/payjoin/manager.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("PayjoinManager.normalizePjEndpoint", () {
    const endpoint = "https://payjo.in/TXJCGKTKXLUUZ#RK1Q0DJS3VVDXWQQTLQ8022QGXSX7ML9PHZ6EDSF6AKEWQG758JPS2EV";

    test("ignores case", () {
      expect(
        PayjoinManager.normalizePjEndpoint(endpoint.toUpperCase()),
        PayjoinManager.normalizePjEndpoint(endpoint.toLowerCase()),
      );
    });

    test("ignores the fragment", () {
      expect(
        PayjoinManager.normalizePjEndpoint(endpoint),
        "https://payjo.in/txjcgktkxluuz",
      );
    });

    test("ignores trailing slashes and whitespace", () {
      expect(
        PayjoinManager.normalizePjEndpoint(" https://payjo.in/TXJCGKTKXLUUZ/ "),
        "https://payjo.in/txjcgktkxluuz",
      );
    });

    test("keeps different mailboxes distinct", () {
      expect(
        PayjoinManager.normalizePjEndpoint("https://payjo.in/AAAA"),
        isNot(PayjoinManager.normalizePjEndpoint("https://payjo.in/BBBB")),
      );
    });

    test("keeps different directories distinct", () {
      expect(
        PayjoinManager.normalizePjEndpoint("https://payjo.in/AAAA"),
        isNot(PayjoinManager.normalizePjEndpoint("https://lets.payjo.in/AAAA")),
      );
    });
  });
}
