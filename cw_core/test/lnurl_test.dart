import 'package:cw_core/lnurl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lnurl', () {
    test('decode lnurl', () {
      final content = decodeLNURL(
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
      expect(content, Uri.parse("https://cake.cash/.well-known/lnurlp/konsti"));
    });

    test('encode lnurl', () {
      final content = encodeLNURL("https://cake.cash/.well-known/lnurlp/konsti");
      expect(content,
          "lnurl1dp68gurn8ghj7cmpddjjucmpwd5z7tnhv4kxctttdehhwm30d3h82unvwqhkkmmwwd6xj9vpzq4");
    });
  });

  group("isBolt11ZeroInvoice", () {
    test("should identify a zero amount invoice", () {
      final invoice = "lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(isBolt11ZeroInvoice(invoice), true);
    });

    test("should identify a non zero amount invoice", () {
      final invoice = "lnbc1u1p5564nxpp5mrklx2pjaggkcfs9r5tfk84wszzy9gypcnrt9yjq7n6uf95s70xqsp59fph78twjra598n2mll2arw5enluy7a4uf4y9a94ddd30hm98njsxq9z0rgqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qcqzpgdql2djkuepqw3hjqsmpddjjq4mpd3kx2aq9qyyssq3nf60ey9fgkf0elu2y8j96rx5pm4gx2a976h8yadx83dyg0ltnysrxhep8e2p3yvz4kf597qk3rttgdy72wwqq0mwr8hdht3pqpchyqq0aa9v0";
      expect(isBolt11ZeroInvoice(invoice), false);
    });

    test("should identify a zero amount prefixed invoice", () {
      final invoice = "lightning:lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(isBolt11ZeroInvoice(invoice), true);
    });

    test("should identify a non zero amount prefixed invoice", () {
      final invoice = "lightning:lnbc1u1p5564nxpp5mrklx2pjaggkcfs9r5tfk84wszzy9gypcnrt9yjq7n6uf95s70xqsp59fph78twjra598n2mll2arw5enluy7a4uf4y9a94ddd30hm98njsxq9z0rgqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qcqzpgdql2djkuepqw3hjqsmpddjjq4mpd3kx2aq9qyyssq3nf60ey9fgkf0elu2y8j96rx5pm4gx2a976h8yadx83dyg0ltnysrxhep8e2p3yvz4kf597qk3rttgdy72wwqq0mwr8hdht3pqpchyqq0aa9v0";
      expect(isBolt11ZeroInvoice(invoice), false);
    });
  });

  group("getBolt11Amount", () {
    test("should identify a zero amount invoice", () {
      final invoice = "lnbc1p5564y8pp5vm48jp3w82yjssrtdhvrjacwwzp59hqjm2lq6fud5thfznyuswgqsp54mykkptx9mlqhpe93f9pcgt9p5ml5xhclyn7qsltqy9ldf25j3qqxqyz5vqnp4qvyndeaqzman7h898jxm98dzkm0mlrsx36s93smrur7h0azyyuxc5rzjqwghf7zxvfkxq5a6sr65g0gdkv768p83mhsnt0msszapamzx2qvuxqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjq25carzepgd4vqsyn44jrk85ezrpju92xyrk9apw4cdjh6yrwt5jgqqqqrt49lmtcqqqqqqqqqqq86qq9qrzjqfvmpdwfesckajzfcf7ff2vqaz9jdgpcsa9xc0fq8ny749dy8y5geapyqr6zgqqqq8hxk2qqae4jsqyugqcqzpgdqq9qyyssqycdyx8r09wgm8vny3n8pf2e0crcdq9mgx3ncxvzsrkljxyrcuwx8zjtje7du40nzdy7x2he67v9asp6ac6ed75r33yyt9pzeepygcmsptc4ve4";
      expect(getBolt11Amount(invoice), null);
    });

    test("should get the amount 1 BTC encoded as bitcoin", () {
      final invoice = "lnbc11p5exaxspp5u6e6lx90rw2vqr2e5axt8ur3v98qnmqfsmh8r0l0mcm7ry70vyvsdqqcqzzsxqrrsssp5eqydmrufk39dwhuxzajwx4xyffn0mlcu3qa8vjwry6qev5gsepkq9qxpqysgqt0zldve9uxt3txjt8wp0gev52lquljgugy26nneue85pjwk5yak4hs2d8533tus07pq5ka6zrnd0ruaeepwres8p7ws5mx63xlwff5sqlxcy8a";
      expect(getBolt11Amount(invoice), 100000000);
    });

    test("should get the amount 0,1 BTC encoded as millibitcoin", () {
      final invoice = "lnbc100m1p5exagmpp5n4c5tml3h8h7k4gthc9papkyeymceqqvcldkng4nvxwzj7nu9jnsdqqcqzzsxqrrsssp58kgzrh7y3pevantduc4yg33aa6r79ed6xgmhr0dy40zc8pxrz5ms9qxpqysgqcq27km3v3wcz6pntmsfnz259zy6tff0uwjz9kamdrvmxmdv09gp44mh0ygn7gweqf4zdev4x8e67p5kcvahethchdkkjexhtk7emuqcpasz0lp";
      expect(getBolt11Amount(invoice), 10000000);
    });

    test("should get the amount 1000 SATS encoded as microbitcoin", () {
      final invoice = "lnbc10u1p5exfgvpp5n3s9dsw9ddax5c3h8437ya7y4g582uyufyna626yr9vqdfjrhwzqdqqcqzzsxqrrsssp5mmkyp5h35fpaxm4063f3kc7d4nmgd4gd8fv8086wxd784m76kmpq9qxpqysgqye9r0vahpjy9l2je6vakxzk3cjnsyx76r29c4amkz4cmapq5tqt5l7rl0emkd003jjvz2d8jqrw6wc4cduvapuyeseh7a855l82wutcpeq30kg";
      expect(getBolt11Amount(invoice), 1000);
    });

    test("should get the amount 1 SAT encoded as nanobitcoin", () {
      final invoice = "lnbc10n1p5exazppp5szh273r6nzvwydzsdlg0ws0vhxwnc6nqtqt4sjt0vu6x6l8t5csqdqqcqzzsxqrrsssp5nkup6uht7xlfqaj8lxpe5kx0ejum9p4pvv3nlnndr9ykzge3393s9qxpqysgqufh05a7qs0ezeckvmh7tjkr9ngng96nq274twg20z45ysp7afpdrttm2ky73cpjwpjqsmtzzd79w6lyvszgmkanwn8mj0jcfunrwv3qprg3z3j";
      expect(getBolt11Amount(invoice), 1);
    });
  });
}
