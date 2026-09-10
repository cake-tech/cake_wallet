import "package:cw_core/amount/money.dart";
import "package:intl/intl.dart";

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
    final formater = NumberFormat("#,###", locale);
    final parts = (isNegative ? amount.substring(1) : amount).split(".");
    final formatted = [formater.format(int.tryParse(parts.first) ?? 0), ...parts.sublist(1)]
        .join(formater.symbols.DECIMAL_SEP);

    return isNegative ? "-$formatted" : formatted;
  }
}
