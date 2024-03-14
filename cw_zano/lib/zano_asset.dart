import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'zano_asset.g.dart';

@HiveType(typeId: ZanoAsset.typeId)
class ZanoAsset extends CryptoCurrency with HiveObjectMixin {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String symbol;
  @HiveField(2)
  final String assetId;
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

  ZanoAsset({
    required this.name,
    required this.symbol,
    required this.assetId,
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

  ZanoAsset.copyWith(ZanoAsset other, String? icon, String? tag)
      : this.name = other.name,
        this.symbol = other.symbol,
        this.assetId = other.assetId,
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

  static const typeId = ZANO_ASSET_TYPE_ID;
  static const zanoAssetsBoxName = 'zanoAssets';
}