import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'erc20_token.g.dart';

@HiveType(typeId: Erc20Token.typeId)
class Erc20Token extends CryptoCurrency with HiveObjectMixin {
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

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  Erc20Token({
    required this.name,
    required this.symbol,
    required this.contractAddress,
    required this.decimal,
    bool enabled = true,
    this.iconPath,
    this.tag,
  })  : _enabled = enabled,
        super(
            name: symbol.toLowerCase(),
            title: symbol.toUpperCase(),
            fullName: name,
            tag: tag,
            iconPath: iconPath,
            decimals: decimal);

  Erc20Token.copyWith(Erc20Token other, String? icon, String? tag)
      : this.name = other.name,
        this.symbol = other.symbol,
        this.contractAddress = other.contractAddress,
        this.decimal = other.decimal,
        this._enabled = other.enabled,
        this.tag = tag,
        this.iconPath = icon,
        super(
          name: other.name,
          title: other.symbol.toUpperCase(),
          fullName: other.name,
          tag: tag,
          iconPath: icon,
          decimals: other.decimal,
        );

  static const typeId = ERC20_TOKEN_TYPE_ID;
  static const boxName = 'Erc20Tokens';
  static const ethereumBoxName = 'EthereumErc20Tokens';
  static const polygonBoxName = 'PolygonErc20Tokens';

  @override
  bool operator ==(other) =>
      (other is Erc20Token && other.contractAddress == contractAddress) ||
      (other is CryptoCurrency && other.title == title);

  @override
  int get hashCode => contractAddress.hashCode;
}
