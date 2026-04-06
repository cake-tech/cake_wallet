import 'package:cw_core/amount/money.dart';

abstract class Currency {
  String get symbol;
  String get name;
  String? get fullName;
  String? get iconPath;
  int get decimals;

  /// Parse the [value] and turn it into [Money]
  Money parseAmount(String value);

  /// Try parsing the [value] and turn it into [Money]
  Money? tryParseAmount(String value);
}
