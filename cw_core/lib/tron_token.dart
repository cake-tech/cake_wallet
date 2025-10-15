// ignore_for_file: annotate_overrides, overridden_fields

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'tron_token.g.dart';

@HiveType(typeId: TronToken.typeId)
class TronToken extends CryptoCurrency with HiveObjectMixin {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String contractAddress;

  @HiveField(3)
  final int decimal;

  @HiveField(4, defaultValue: true)
  bool _enabled;

  @HiveField(5)
  final String? iconPath;

  @HiveField(6)
  final String? tag;

  @HiveField(7, defaultValue: false)
  final bool isPotentialScam;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  TronToken({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimal,
    bool enabled = true,
    this.iconPath,
    this.tag = 'TRX',
    this.isPotentialScam = false,
  })  : _enabled = enabled,
        super(
          name: symbol.toLowerCase(),
          title: symbol.toUpperCase(),
          fullName: name,
          tag: tag,
          iconPath: iconPath,
          decimals: decimal,
          isPotentialScam: isPotentialScam,
        );

  TronToken.copyWith(TronToken other, {String? icon, String? tag, bool? enabled})
      : name = other.name,
        symbol = other.symbol,
        contractAddress = other.contractAddress,
        decimal = other.decimal,
        _enabled = enabled ?? other.enabled,
        tag = tag ?? other.tag,
        iconPath = icon ?? other.iconPath,
        isPotentialScam = other.isPotentialScam,
        super(
          name: other.name,
          title: other.symbol.toUpperCase(),
          fullName: other.name,
          tag: tag ?? other.tag,
          iconPath: icon ?? other.iconPath,
          decimals: other.decimal,
          isPotentialScam: other.isPotentialScam,
        );

  static const typeId = TRON_TOKEN_TYPE_ID;
  static const boxName = 'TronTokens';

  @override
  bool operator ==(other) =>
      (other is TronToken && other.contractAddress == contractAddress) ||
      (other is CryptoCurrency && other.title == title);

  @override
  int get hashCode => contractAddress.hashCode;
}
