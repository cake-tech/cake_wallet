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
}
