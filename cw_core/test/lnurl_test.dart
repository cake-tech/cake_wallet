import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/lnurl.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/utils/tor/abstract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lnurl', () {
    test('decode lnurl', () {
      final content = LNURL.decode(
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
      expect(content, Uri.parse("https://cake.cash/.well-known/lnurlp/konsti"));
    });

    // This tests includes a rest request to an URL that expired and due to the lack of an alternative URL we ignore this test
    // test('get amount', () async {
    //   CakeTor.instance = await CakeTorInstance.getInstance();
    //
    //   final content = await LNURL.getPayRequestAmount(
    //       "LNURL1DP68GURN8GHJ7CTSWQHXY6T5WFJHZAT9WD6ZU6T09AUZ7URJDAU8JTMKXYHKCM308A5N6MNHVVNXJEPAXGMNWWPEX3JRGDTPXVNXZ0FCX5CRQVPSXQNX602VFE24YNP9XGC8W6T5DQJNYVRPD4HH2MN5GTRNLZ");
    //   expect(content, Money.fromInt(8500, CryptoCurrency.btcln));
    // });

    test('get no amount', () async {
      CakeTor.instance = await CakeTorInstance.getInstance();

      final content = await LNURL.getPayRequestAmount(
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
      expect(content, null);
    });

    test('encode lnurl', () {
      final content = LNURL.encode("https://cake.cash/.well-known/lnurlp/konsti");
      expect(content,
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
    });
  });

  group("isBolt11ZeroInvoice", () {
    test("should identify a zero amount invoice", () {
      final invoice =
          "lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(isBolt11ZeroInvoice(invoice), true);
    });

    test("should identify a non zero amount invoice", () {
      final invoice =
          "lnbc1u1p5564nxpp5mrklx2pjaggkcfs9r5tfk84wszzy9gypcnrt9yjq7n6uf95s70xqsp59fph78twjra598n2mll2arw5enluy7a4uf4y9a94ddd30hm98njsxq9z0rgqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qcqzpgdql2djkuepqw3hjqsmpddjjq4mpd3kx2aq9qyyssq3nf60ey9fgkf0elu2y8j96rx5pm4gx2a976h8yadx83dyg0ltnysrxhep8e2p3yvz4kf597qk3rttgdy72wwqq0mwr8hdht3pqpchyqq0aa9v0";
      expect(isBolt11ZeroInvoice(invoice), false);
    });

    test("should identify a zero amount prefixed invoice", () {
      final invoice =
          "lightning:lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(isBolt11ZeroInvoice(invoice), true);
    });

    test("should identify a non zero amount prefixed invoice", () {
      final invoice =
          "lightning:lnbc1u1p5564nxpp5mrklx2pjaggkcfs9r5tfk84wszzy9gypcnrt9yjq7n6uf95s70xqsp59fph78twjra598n2mll2arw5enluy7a4uf4y9a94ddd30hm98njsxq9z0rgqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qcqzpgdql2djkuepqw3hjqsmpddjjq4mpd3kx2aq9qyyssq3nf60ey9fgkf0elu2y8j96rx5pm4gx2a976h8yadx83dyg0ltnysrxhep8e2p3yvz4kf597qk3rttgdy72wwqq0mwr8hdht3pqpchyqq0aa9v0";
      expect(isBolt11ZeroInvoice(invoice), false);
    });
  });

  group("getBolt11Amount", () {
    test("should identify a zero amount invoice", () {
      final invoice =
          "lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(getBolt11Amount(invoice), null);
    });

    test("should get the amount 1 BTC encoded as bitcoin", () {
      final invoice =
          "lnbc11p5exaxspp5u6e6lx90rw2vqr2e5axt8ur3v98qnmqfsmh8r0l0mcm7ry70vyvsdqqcqzzsxqrrsssp5eqydmrufk39dwhuxzajwx4xyffn0mlcu3qa8vjwry6qev5gsepkq9qxpqysgqt0zldve9uxt3txjt8wp0gev52lquljgugy26nneue85pjwk5yak4hs2d8533tus07pq5ka6zrnd0ruaeepwres8p7ws5mx63xlwff5sqlxcy8a";
      expect(getBolt11Amount(invoice), Money.fromInt(100000000, CryptoCurrency.btcln));
    });

    test("should get the amount 0,1 BTC encoded as millibitcoin", () {
      final invoice =
          "lnbc100m1p5exagmpp5n4c5tml3h8h7k4gthc9papkyeymceqqvcldkng4nvxwzj7nu9jnsdqqcqzzsxqrrsssp58kgzrh7y3pevantduc4yg33aa6r79ed6xgmhr0dy40zc8pxrz5ms9qxpqysgqcq27km3v3wcz6pntmsfnz259zy6tff0uwjz9kamdrvmxmdv09gp44mh0ygn7gweqf4zdev4x8e67p5kcvahethchdkkjexhtk7emuqcpasz0lp";
      expect(getBolt11Amount(invoice), Money.fromInt(10000000, CryptoCurrency.btcln));
    });

    test("should get the amount 1000 SATS encoded as microbitcoin", () {
      final invoice =
          "lnbc10u1p5exfgvpp5n3s9dsw9ddax5c3h8437ya7y4g582uyufyna626yr9vqdfjrhwzqdqqcqzzsxqrrsssp5mmkyp5h35fpaxm4063f3kc7d4nmgd4gd8fv8086wxd784m76kmpq9qxpqysgqye9r0vahpjy9l2je6vakxzk3cjnsyx76r29c4amkz4cmapq5tqt5l7rl0emkd003jjvz2d8jqrw6wc4cduvapuyeseh7a855l82wutcpeq30kg";
      expect(getBolt11Amount(invoice), Money.fromInt(1000, CryptoCurrency.btcln));
    });

    test("should get the amount 1 SAT encoded as nanobitcoin", () {
      final invoice =
          "lnbc10n1p5exazppp5szh273r6nzvwydzsdlg0ws0vhxwnc6nqtqt4sjt0vu6x6l8t5csqdqqcqzzsxqrrsssp5nkup6uht7xlfqaj8lxpe5kx0ejum9p4pvv3nlnndr9ykzge3393s9qxpqysgqufh05a7qs0ezeckvmh7tjkr9ngng96nq274twg20z45ysp7afpdrttm2ky73cpjwpjqsmtzzd79w6lyvszgmkanwn8mj0jcfunrwv3qprg3z3j";
      expect(getBolt11Amount(invoice), Money.fromInt(1, CryptoCurrency.btcln));
    });
  });

  group("getBolt11Description", () {
    const invoiceWithDescription =
        "lnbc1u1p5564nxpp5mrklx2pjaggkcfs9r5tfk84wszzy9gypcnrt9yjq7n6uf95s70xqsp59fph78twjra598n2mll2arw5enluy7a4uf4y9a94ddd30hm98njsxq9z0rgqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qcqzpgdql2djkuepqw3hjqsmpddjjq4mpd3kx2aq9qyyssq3nf60ey9fgkf0elu2y8j96rx5pm4gx2a976h8yadx83dyg0ltnysrxhep8e2p3yvz4kf597qk3rttgdy72wwqq0mwr8hdht3pqpchyqq0aa9v0";

    test("should read the description of an invoice", () {
      expect(getBolt11Description(invoiceWithDescription), "Send to Cake Wallet");
    });

    test("should read the description of a prefixed invoice", () {
      expect(getBolt11Description("lightning:$invoiceWithDescription"), "Send to Cake Wallet");
    });

    test("should read the description of an uppercase invoice", () {
      expect(getBolt11Description(invoiceWithDescription.toUpperCase()), "Send to Cake Wallet");
    });

    test("should read a non-ASCII description", () {
      const invoice =
          "lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpu9qrsgqhtjpauu9ur7fw2thcl4y9vfvh4m9wlfyz2gem29g5ghe2aak2pm3ps8fdhtceqsaagty2vph7utlgj48u0ged6a337aewvraedendscp573dxr";
      expect(getBolt11Description(invoice), "ナンセンス 1杯");
    });

    test("should read an empty description", () {
      const invoice =
          "lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(getBolt11Description(invoice), "");
    });

    test("should return null for an invoice that only commits to a description hash", () {
      const invoice =
          "lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs9qrsgq7ea976txfraylvgzuxs8kgcw23ezlrszfnh8r6qtfpr6cxga50aj6txm9rxrydzd06dfeawfk6swupvz4erwnyutnjq7x39ymw6j38gp7ynn44";
      expect(getBolt11Amount(invoice), Money.fromInt(2000000, CryptoCurrency.btcln));
      expect(getBolt11Description(invoice), null);
    });

    test("should return null for input that is not an invoice", () {
      expect(
        getBolt11Description(
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4",
        ),
        null,
      );
      expect(getBolt11Description("bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"), null);
      expect(getBolt11Description("alice@cake.cash"), null);
    });
  });
}
