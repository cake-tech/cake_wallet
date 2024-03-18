import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_zano/zano_asset.dart';

class Balance {
  final ZanoAsset assetInfo;
  final int awaitingIn;
  final int awaitingOut;
  final int total;
  final int unlocked;

  Balance(
      {required this.assetInfo,
      required this.awaitingIn,
      required this.awaitingOut,
      required this.total,
      required this.unlocked});

  @override
  String toString() => '$assetInfo: ${AmountConverter.amountIntToString(CryptoCurrency.zano, total)}/${AmountConverter.amountIntToString(CryptoCurrency.zano, unlocked)}';

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        assetInfo:
            ZanoAsset.fromJson(json['asset_info'] as Map<String, dynamic>? ?? {}),
        awaitingIn: json['awaiting_in'] as int? ?? 0,
        awaitingOut: json['awaiting_out'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        unlocked: json['unlocked'] as int? ?? 0,
      );
}
