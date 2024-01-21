import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hive_type_ids.dart';
import 'package:hive/hive.dart';
import 'package:solana/metaplex.dart';

part 'spl_token.g.dart';

@HiveType(typeId: SPLToken.typeId)
class SPLToken extends CryptoCurrency with HiveObjectMixin {
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

  @HiveField(6)
  final String logoUrl;

  SPLToken({
    required this.name,
    required this.symbol,
    required this.mintAddress,
    required this.decimal,
    bool enabled = true,
    required this.mint,
    required this.logoUrl,
  })  : _enabled = enabled,
        super(
            name: symbol.toLowerCase(),
            title: symbol.toUpperCase(),
            fullName: name,
            tag: 'SOL',
            iconPath: logoUrl,
            decimals: decimal);

  factory SPLToken.fromMetadata({
    required String name,
    required String mint,
    required String symbol,
    required String mintAddress,
  }) {
    return SPLToken(
      name: name,
      symbol: symbol,
      mintAddress: mintAddress,
      decimal: 0,
      mint: mint,
      logoUrl: '',
    );
  }

  factory SPLToken.cryptoCurrency({
    required String name,
    required String symbol,
    required int decimals,
    required String logoUrl,
    required String mint,
  }) {
    return SPLToken(
      name: name,
      symbol: symbol,
      decimal: decimals,
      mint: mint,
      logoUrl: logoUrl,
      mintAddress: '',
    );
  }

  bool get enabled => _enabled;

  set enabled(bool value) => _enabled = value;

  static const typeId = SPL_TOKEN_TYPE_ID;
  static const boxName = 'SPLTokens';

  @override
  bool operator ==(other) =>
      (other is SPLToken && other.mintAddress == mintAddress) ||
      (other is CryptoCurrency && other.title == title);

  @override
  int get hashCode => mintAddress.hashCode;
}

class NFT extends SPLToken {
  final ImageInfo? imageInfo;

  NFT(
    String mint,
    String name,
    String symbol,
    String mintAddress,
    int decimal,
    String logoUrl,
    this.imageInfo,
  ) : super(
          name: name,
          symbol: symbol,
          mintAddress: mintAddress,
          decimal: decimal,
          mint: mint,
          logoUrl: logoUrl,
        );
}

class ImageInfo {
  final String uri;
  final OffChainMetadata? data;

  const ImageInfo(this.uri, this.data);
}
