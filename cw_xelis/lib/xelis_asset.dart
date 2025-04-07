import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';

part 'xelis_asset.g.dart';

@HiveType(typeId: XelisAsset.typeId)
class XelisAsset extends CryptoCurrency with HiveObjectMixin {
  @override
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String id;

  @HiveField(3)
  final int decimals;

  @HiveField(4, defaultValue: true)
  bool _enabled;

  @override
  @HiveField(5)
  final String? iconPath;

  @override
  @HiveField(6)
  final String? tag;

  @override
  @HiveField(7, defaultValue: false)
  final bool isPotentialScam;

  XelisAsset({
    required this.name,
    required this.symbol,
    required this.id,
    required this.decimals,
    this.iconPath,
    this.tag = 'XEL',
    bool enabled = true,
    this.isPotentialScam = false,
  })  : _enabled = enabled,
        super(
          name: id.toLowerCase(),
          title: symbol.toUpperCase(),
          fullName: name,
          tag: tag,
          iconPath: iconPath,
          decimals: decimals,
          isPotentialScam: isPotentialScam,
        );

  factory XelisAsset.fromMetadata({
    required String name,
    required String id,
    required String symbol,
    required int decimals,
    String? iconPath,
    bool isPotentialScam = false,
  }) {
    return XelisAsset(
      name: name,
      symbol: symbol,
      decimals: decimals,
      id: id,
      iconPath: iconPath,
      isPotentialScam: isPotentialScam,
    );
  }

  @override
  bool get enabled => _enabled;

  @override
  set enabled(bool value) => _enabled = value;

  XelisAsset.copyWith(XelisAsset other, String? icon, String? tag)
      : name = other.name,
        symbol = other.symbol,
        decimals = other.decimals,
        _enabled = other.enabled,
        id = other.id,
        tag = other.tag,
        iconPath = icon,
        isPotentialScam = other.isPotentialScam,
        super(
          title: other.symbol.toUpperCase(),
          name: other.symbol.toLowerCase(),
          decimals: other.decimals,
          fullName: other.name,
          tag: other.tag,
          iconPath: icon,
          isPotentialScam: other.isPotentialScam,
        );

  static const typeId = XELIS_ASSET_TYPE_ID;
  static const boxName = 'XelisAssets';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is XelisAsset) {
      return other.id == id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;
}
