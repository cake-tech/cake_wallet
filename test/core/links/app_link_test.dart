import "package:cake_wallet/core/links/app_link.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("appLinkFor", () {
    final cases = <String, Type>{
      "cakewallet://wc?uri=wc%3Aabc%402%3Frelay-protocol%3Dirn": WalletConnectLink,
      "wc:7f6e504bfad60b485450578e05678ed3e8e8c4751d3c6160be17160d63ec90f9@2?relay-protocol=irn":
          WalletConnectLink,
      "quickaction://send": QuickActionLink,
      "quickaction://receive": QuickActionLink,
      "nano-gpt://exchange?address=nano_1abc&amount=1": NanoGptLink,
      "nano-gpt://send?address=nano_1abc": NanoGptLink,
      "NANO-GPT://buy": NanoGptLink,
      "https://xmr-node.cakewallet.com:18081": NodeLink,
      "http://127.0.0.1:18081": NodeLink,
      "tcp://electrum.cakewallet.com:50001": NodeLink,
      "bitcoin:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq?amount=0.001&label=Bob Shop": PaymentLink,
      "bitcoin:?r=https://bitpay.com/i/abc": PaymentLink,
      "monero:4AdUndXHHZ6cfufTMvppY6JwXNouMBzSkbLYfpAV5Usx": PaymentLink,
      "lightning:lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypq":
          PaymentLink,
      "lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekvcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxfq5fns":
          PaymentLink,
      "LIGHTNING:LNBC10U1P5EXFGVPP5N3S9DSW9DDAX5C3H8437YA7Y4G582UYUFYNA626YR9VQDFJRHWZQDQQCQZZSXQRRSSSP5MMKYP5H35FPAXM4063F3KC7D4NMGD4GD8FV8086WXD784M76KMPQ9QXPQYSGQYE9R0VAHPJY9L2JE6VAKXZK3CJNSYX76R29C4AMKZ4CMAPQ5TQT5L7RL0EMKD003JJVZ2D8JQRW6WC4CDUVAPUYESEH7A855L82WUTCPEQ30KG":
          PaymentLink,
      "LIGHTNING:LNURL1DP68GURN8GHJ7V33D45K7TNNWPSKXEF00FSHQCN00QHKZURF9AMRZTMVDE6HYMP0FPH8Q42NVF5Y2DNSDEV8SKJZVD54QUP4X44R7URFDC7NZVSFF8MG6":
          PaymentLink,
      "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq": PaymentLink,
    };

    cases.forEach((link, type) {
      test("$link -> $type", () {
        final uri = Uri.parse(link);
        final appLink = appLinkFor(uri);

        expect(appLink.runtimeType, type);
        expect(appLink.uri, uri);
      });
    });
  });
}
