import 'package:cw_core/crypto_currency.dart';
import 'package:cw_zano/zano_asset.dart';

class DefaultZanoAssets {
  final List<ZanoAsset> _defaultAssets = [
    ZanoAsset(
      assetId: 'd6329b5b1f7c0805b5c345f4957554002a2f557845f64d7645dae0e051a6498a',
      decimal: 12,
      name: 'Zano',
      symbol: 'ZANO',
    ),
    ZanoAsset(
      assetId: '123',
      decimal: 12,
      name: 'Test Coin',
      symbol: 'TC',
    ),
  ];

  List<ZanoAsset> get initialZanoAssets => _defaultAssets.map(
        (token) {
          String? iconPath;
          if (CryptoCurrency.all.any((element) => element.title.toUpperCase() == token.symbol.toUpperCase())) {
            iconPath = CryptoCurrency.all.singleWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase()).iconPath;
          }
          return ZanoAsset.copyWith(token, iconPath, 'ZANO');
        },
      ).toList();
}
