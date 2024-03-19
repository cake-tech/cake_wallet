import 'package:cw_core/crypto_currency.dart';
import 'package:cw_zano/model/zano_asset.dart';

class DefaultZanoAssets {
  final List<ZanoAsset> _defaultAssets = [
    ZanoAsset(
      decimalPoint: 12,
      fullName: 'Confidential token',
      assetId: 'cc4e69455e63f4a581257382191de6856c2156630b3fba0db4bdd73ffcfb36b6',
      owner: '32911fabcf90b9731a152d2a3a75fcbb0a46c78e2f502678bae44c3d6823b4ce',
      ticker: 'CT',
      enabled: false,
    ),
    ZanoAsset(
      decimalPoint: 12,
      fullName: '새로운경제',
      assetId: 'bb9590162509f956ff79851fb1bc0ced6646f5d5ba7eae847a9f21c92c39437c',
      owner: '32911fabcf90b9731a152d2a3a75fcbb0a46c78e2f502678bae44c3d6823b4ce',
      ticker: '새로운경제',
      enabled: false,
    ),
  ];

  List<ZanoAsset> get initialZanoAssets => _defaultAssets.map(
        (asset) {
          String? iconPath;
          try {
            iconPath = CryptoCurrency.all.firstWhere((element) => element.title.toUpperCase() == asset.title.toUpperCase()).iconPath;
          } catch (_) {}
          return ZanoAsset.copyWith(asset, iconPath, 'ZANO');
        },
      ).toList();
}
