import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'spl_token.g.dart';

@HiveType(typeId: SPLToken.typeId)
class SPLToken extends CryptoCurrency with HiveObjectMixin {
  @override
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String mintAddress;

  @HiveField(3)
  final int decimal;

  @HiveField(4, defaultValue: true)
  bool _enabled;

  @HiveField(5)
  final String mint;

  @override
  @HiveField(6)
  final String? iconPath;

  @override
  @HiveField(7)
  final String? tag;

  @override
  @HiveField(8, defaultValue: false)
  final bool isPotentialScam;

  SPLToken({
    required this.name,
    required this.symbol,
    required this.mintAddress,
    required this.decimal,
    required this.mint,
    this.iconPath,
    this.tag = 'SOL',
    bool enabled = true,
    this.isPotentialScam = false,
  })  : _enabled = enabled,
        super(
          name: mint.toLowerCase(),
          title: symbol.toUpperCase(),
          fullName: name,
          tag: tag,
          iconPath: iconPath,
          decimals: decimal,
          isPotentialScam: isPotentialScam,
        );

  factory SPLToken.fromMetadata({
    required String name,
    required String mint,
    required String symbol,
    required String mintAddress,
    String? iconPath,
    bool isPotentialScam = false,
  }) {
    return SPLToken(
      name: name,
      symbol: symbol,
      mintAddress: mintAddress,
      decimal: 0,
      mint: mint,
      iconPath: iconPath,
      isPotentialScam: isPotentialScam,
    );
  }

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  SPLToken.copyWith(SPLToken other, {String? icon, String? tag, bool? enabled})
      : name = other.name,
        symbol = other.symbol,
        mintAddress = other.mintAddress,
        decimal = other.decimal,
        _enabled = enabled ?? other.enabled,
        mint = other.mint,
        tag = tag ?? other.tag,
        iconPath = icon ?? other.iconPath,
        isPotentialScam = other.isPotentialScam,
        super(
          title: other.symbol.toUpperCase(),
          name: other.symbol.toLowerCase(),
          decimals: other.decimal,
          fullName: other.name,
          tag: other.tag,
          iconPath: icon,
          isPotentialScam: other.isPotentialScam,
        );

  static const typeId = SPL_TOKEN_TYPE_ID;
  static const boxName = 'SPLTokens';

  @override
  bool operator ==(other) =>
      (other is SPLToken && other.mintAddress == mintAddress) ||
      (other is CryptoCurrency && other.title == title);

  @override
  int get hashCode => mintAddress.hashCode;
}
