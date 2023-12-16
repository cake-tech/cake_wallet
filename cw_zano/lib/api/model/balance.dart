import 'package:cw_zano/api/model/asset_info.dart';

class Balance {
  final AssetInfo assetInfo;
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

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        assetInfo:
            AssetInfo.fromJson(json['asset_info'] as Map<String, dynamic>),
        awaitingIn: json['awaiting_in'] as int,
        awaitingOut: json['awaiting_out'] as int,
        total: json['total'] as int,
        unlocked: json['unlocked'] as int,
      );
}
