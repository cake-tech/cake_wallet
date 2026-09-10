import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_amount_format.dart";

extension WithLocalSeparator on Money {
  String toLocalStringWithSymbol({
    int? fractionalDigits,
    bool trimZeros = true,
    bool useBaseUnit = false,
    bool withSymbolPrefix = false,
    String? locale,
  }) {
    final amount = toLocalStringWithPrecision(
      fractionalDigits: fractionalDigits,
      trimZeros: trimZeros,
      useBaseUnit: useBaseUnit,
      locale: locale,
    );
    final symbol = getSymbol(useBaseUnit: useBaseUnit);

    return withSymbolPrefix ? "$symbol $amount" : "$amount $symbol";
  }

  String toLocalStringWithPrecision({
    int? fractionalDigits,
    bool trimZeros = true,
    bool useBaseUnit = false,
    String? locale,
  }) =>
      _withLocalSeparator(
        toStringWithPrecision(
          fractionalDigits: fractionalDigits,
          trimZeros: trimZeros,
          useBaseUnit: useBaseUnit,
        ),
        locale: locale,
      );

  String _withLocalSeparator(String amount, {String? locale}) {
    final isNegative = amount.startsWith("-");
    final formatted = (isNegative ? amount.substring(1) : amount).withLocalSeperator(locale);

    return isNegative ? "-$formatted" : formatted;
  }
}
