class AddRemoveAssetsWhitelistParams {
  final String assetId;

  AddRemoveAssetsWhitelistParams({required this.assetId});

  Map<String, dynamic> toJson() => {
    'asset_id': assetId,
  };
}