import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'zano_asset.g.dart';

@HiveType(typeId: ZanoAsset.typeId)
class ZanoAsset extends CryptoCurrency with HiveObjectMixin {
  @HiveField(0)
  final String fullName;
  @HiveField(1)
  final String ticker;
  @HiveField(2)
  final String assetId;
  @HiveField(3)
  final int decimalPoint;
  @HiveField(4, defaultValue: true)
  bool _enabled;
  @HiveField(5)
  final String? iconPath;
  @HiveField(6)
  final String? tag;
  @HiveField(7)
  final String owner;
  @HiveField(8)
  final String metaInfo;
  @HiveField(9)
  final int currentSupply;
  @HiveField(10)
  final bool hiddenSupply;
  @HiveField(11)
  final int totalMaxSupply;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  ZanoAsset({
    this.fullName = '',
    this.ticker = '',
    required this.assetId,
    this.decimalPoint = defaultDecimalPoint,
    bool enabled = true,
    this.iconPath,
    this.tag,
    this.owner = defaultOwner,
    this.metaInfo = '',
    this.currentSupply = 0,
    this.hiddenSupply = false,
    this.totalMaxSupply = 0,
  })  : _enabled = enabled,
        super(
          name: fullName,
          title: ticker.toUpperCase(),
          fullName: fullName,
          tag: tag,
          iconPath: iconPath,
          decimals: decimalPoint,
        );

  ZanoAsset.copyWith(ZanoAsset other, String? icon, String? tag, {String? assetId, bool enabled = false})
      : this.fullName = other.fullName,
        this.ticker = other.ticker,
        this.assetId = assetId ?? other.assetId,
        this.decimalPoint = other.decimalPoint,
        this._enabled = enabled || other.enabled,
        this.tag = tag,
        this.iconPath = icon,
        this.currentSupply = other.currentSupply,
        this.hiddenSupply = other.hiddenSupply,
        this.metaInfo = other.metaInfo,
        this.owner = other.owner,
        this.totalMaxSupply = other.totalMaxSupply,
        super(
          name: other.name,
          title: other.ticker.toUpperCase(),
          fullName: other.name,
          tag: tag,
          iconPath: icon,
          decimals: other.decimalPoint,
        );

  factory ZanoAsset.fromJson(Map<String, dynamic> json) => ZanoAsset(
        assetId: json['asset_id'] as String? ?? '',
        currentSupply: json['current_supply'] as int? ?? 0,
        decimalPoint: json['decimal_point'] as int? ?? defaultDecimalPoint,
        fullName: json['full_name'] as String? ?? '',
        hiddenSupply: json['hidden_supply'] as bool? ?? false,
        metaInfo: json['meta_info'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
        ticker: json['ticker'] as String? ?? '',
        totalMaxSupply: json['total_max_supply'] as int? ?? 0,
      );

  @override
  String toString() => '$ticker (${assetId.substring(0, 4)}...${assetId.substring(assetId.length - 4)})';

  static const typeId = ZANO_ASSET_TYPE_ID;
  static const zanoAssetsBoxName = 'zanoAssetsBox';
  static const defaultDecimalPoint = 12;
  static const defaultOwner = '0000000000000000000000000000000000000000000000000000000000000000';
}
