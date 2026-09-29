import "dart:math";

import "package:cw_core/amount/money.dart";
import "package:cw_core/amount/utils.dart";
import "package:cw_core/currency/currency.dart";

/// Turn a double representation of a currency amount to a proper Money representation
/// truncating currencies with more than 20 decimals because double can not handle more
extension ToMoney on double {
  Money<T>? tryToMoney<T extends Currency>(T currency) => Money.tryParse(_toSafeString(currency), currency);

  Money<T> toMoney<T extends Currency>(T currency) => Money.parse(_toSafeString(currency), currency);

  String _toSafeString(Currency currency) =>
      trimTrailingFractionZeros(toStringAsFixed(min(currency.decimals, 20)));
}
