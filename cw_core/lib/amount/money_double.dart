import "dart:math";
import "package:cw_core/amount/money.dart";
import "package:cw_core/currency.dart";

extension ToMoney on double {
  /// Turn a double representation of a currency amount to a proper Money representation
  /// truncating currencies with more than 20 decimals because double can not handle more
  Money? tryToMoney(Currency currency) =>
      Money.tryParse(toStringAsFixed(min(currency.decimals, 20)), currency);

  Money toMoney(Currency currency) =>
      Money.parse(toStringAsFixed(min(currency.decimals, 20)), currency);
}
