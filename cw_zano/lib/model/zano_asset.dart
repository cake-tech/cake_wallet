import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:cw_zano/zano_formatter.dart';
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
  // @HiveField(6)
  // final String? tag;
  @HiveField(6)
  final String owner;
  @HiveField(7)
  final String metaInfo;
  @HiveField(8)
  final int currentSupply;
  @HiveField(9)
  final bool hiddenSupply;
  @HiveField(10)
  final int totalMaxSupply;
  @HiveField(11)
  final bool isInGlobalWhitelist;

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  ZanoAsset({
    this.fullName = '',
    this.ticker = '',
    required this.assetId,
    this.decimalPoint = ZanoFormatter.defaultDecimalPoint,
    bool enabled = true,
    this.iconPath,
    this.owner = defaultOwner,
    this.metaInfo = '',
    this.currentSupply = 0,
    this.hiddenSupply = false,
    this.totalMaxSupply = 0,
    this.isInGlobalWhitelist = false,
  })  : _enabled = enabled,
        super(
          name: fullName,
          title: ticker.toUpperCase(),
          fullName: fullName,
          tag: 'ZANO',
          iconPath: iconPath,
          decimals: decimalPoint,
        );

  ZanoAsset.copyWith(ZanoAsset other, {String? icon,  String? assetId, bool enabled = true})
      : this.fullName = other.fullName,
        this.ticker = other.ticker,
        this.assetId = assetId ?? other.assetId,
        this.decimalPoint = other.decimalPoint,
        this._enabled = enabled && other.enabled,
        this.iconPath = icon,
        this.currentSupply = other.currentSupply,
        this.hiddenSupply = other.hiddenSupply,
        this.metaInfo = other.metaInfo,
        this.owner = other.owner,
        this.totalMaxSupply = other.totalMaxSupply,
        this.isInGlobalWhitelist = other.isInGlobalWhitelist,
        super(
          name: other.name,
          title: other.ticker.toUpperCase(),
          fullName: other.name,
          tag: 'ZANO',
          iconPath: icon,
          decimals: other.decimalPoint,
          enabled: enabled,
        );

  factory ZanoAsset.fromJson(Map<String, dynamic> json, {bool isInGlobalWhitelist = false}) => ZanoAsset(
        assetId: json['asset_id'] as String? ?? '',
        currentSupply: json['current_supply'] as int? ?? 0,
        decimalPoint: json['decimal_point'] as int? ?? ZanoFormatter.defaultDecimalPoint,
        fullName: json['full_name'] as String? ?? '',
        hiddenSupply: json['hidden_supply'] as bool? ?? false,
        metaInfo: json['meta_info'] as String? ?? '',
        owner: json['owner'] as String? ?? '',
        ticker: json['ticker'] as String? ?? '',
        totalMaxSupply: json['total_max_supply'] as int? ?? 0,
        isInGlobalWhitelist: isInGlobalWhitelist,
      );

  static const typeId = ZANO_ASSET_TYPE_ID;
  static const zanoAssetsBoxName = 'zanoAssetsBox';    
  static const defaultOwner = '0000000000000000000000000000000000000000000000000000000000000000';
}
