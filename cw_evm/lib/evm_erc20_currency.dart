import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency.dart';

class ERC20Currency implements Currency {
  @override
  final int decimals;

  @override
  String get name => symbol;

  @override
  final String symbol;

  @override
  final String? fullName;

  @override
  final String? iconPath;

  const ERC20Currency({
    required this.decimals,
    required this.symbol,
    this.fullName,
    this.iconPath,
  });

  @override
  Money parseAmount(String value) => Money.parse(value, this);

  @override
  Money? tryParseAmount(String value) => Money.tryParse(value, this);

  @override
  String? get tag => null;

  @override
  bool operator ==(Object other) =>
      other is ERC20Currency && other.decimals == decimals && other.symbol == symbol;

  @override
  int get hashCode => decimals.hashCode ^ symbol.hashCode;
}
