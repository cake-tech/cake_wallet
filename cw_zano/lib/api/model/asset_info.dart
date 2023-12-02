class AssetInfo {
  final String assetId;
  final int currentSupply;
  final int decimalPoint;
  final String fullName;
  final bool hiddenSupply;
  final String metaInfo;
  final String owner;
  final String ticker;
  final int totalMaxSupply;

  AssetInfo(
      {required this.assetId,
      required this.currentSupply,
      required this.decimalPoint,
      required this.fullName,
      required this.hiddenSupply,
      required this.metaInfo,
      required this.owner,
      required this.ticker,
      required this.totalMaxSupply});

  factory AssetInfo.fromJson(Map<String, dynamic> json) => AssetInfo(
        assetId: json['asset_id'] as String,
        currentSupply: json['current_supply'] as int,
        decimalPoint: json['decimal_point'] as int,
        fullName: json['full_name'] as String,
        hiddenSupply: json['hidden_supply'] as bool,
        metaInfo: json['meta_info'] as String,
        owner: json['owner'] as String,
        ticker: json['ticker'] as String,
        totalMaxSupply: json['total_max_supply'] as int,
      );
}
