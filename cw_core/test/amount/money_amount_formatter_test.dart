import "package:cw_core/amount/money.dart";
import "package:cw_core/amount/money_local.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:flutter_test/flutter_test.dart";

import "utils.dart";

class _BracketedEuro extends FiatCurrency implements AmountFormatter {
  const _BracketedEuro() : super(symbol: "EUR", countryCode: "eur", fullName: "Euro");

  @override
  String format(String amount) => "<$amount €>";
}

void main() {
  const bracketedEuro = _BracketedEuro();

  test("lets a currency that formats amounts place its own sign", () {
    final money = Money.parse("1234.5", bracketedEuro);

    expect(money.toStringWithSymbol(trimZeros: false), "<1234.50 €>");
    expect(money.toStringWithSymbol(withSymbolPrefix: true), "<1234.5 €>");
    expect(money.toLocalStringWithSymbol(trimZeros: false, locale: "de"), "<1.234,50 €>");
  });

  test("keeps the symbol after the amount for every other currency", () {
    expect(Money.parse("1.5", CryptoCurrency.btc).toStringWithSymbol(), "1.5 BTC");
    expect(Money.parse("1.5", EUR).toStringWithSymbol(withSymbolPrefix: true), "EUR 1.5");
  });
}
