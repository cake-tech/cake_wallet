// class AssetDescriptor {
//   static const defaultDecimalPoint = 12;
//   final String assetId;
//   final int currentSupply;
//   final int decimalPoint;
//   final String fullName;
//   final bool hiddenSupply;
//   final String metaInfo;
//   final String owner;
//   final String ticker;
//   final int totalMaxSupply;

//   AssetDescriptor({
//     required this.assetId,
//     required this.currentSupply,
//     required this.decimalPoint,
//     required this.fullName,
//     required this.hiddenSupply,
//     required this.metaInfo,
//     required this.owner,
//     required this.ticker,
//     required this.totalMaxSupply,
//   });

//   factory AssetDescriptor.fromJson(Map<String, dynamic> json) =>
//       AssetDescriptor(
//         assetId: json['asset_id'] as String? ?? '',
//         currentSupply: json['current_supply'] as int? ?? 0,
//         decimalPoint: json['decimal_point'] as int? ?? defaultDecimalPoint,
//         fullName: json['full_name'] as String? ?? '',
//         hiddenSupply: json['hidden_supply'] as bool? ?? false,
//         metaInfo: json['meta_info'] as String? ?? '',
//         owner: json['owner'] as String? ?? '',
//         ticker: json['ticker'] as String? ?? '',
//         totalMaxSupply: json['total_max_supply'] as int? ?? 0,
//       );
    
// }
