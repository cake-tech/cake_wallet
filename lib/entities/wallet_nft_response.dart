import "package:cw_core/utils/ipfs_url.dart";
import "package:cw_core/utils/nft_text.dart";

class WalletNFTsResponseModel {
  final int? page;
  final int? pageSize;

  final List<NFTAssetModel>? result;
  final String? status;

  WalletNFTsResponseModel({this.page, this.pageSize, this.result, this.status});

  factory WalletNFTsResponseModel.fromJson(Map<String, dynamic> json) {
    return WalletNFTsResponseModel(
      page: json['page'] as int?,
      pageSize: json['page_size'] as int?,
      result: (json['result'] as List?)
          ?.map((x) => NFTAssetModel.fromJson(x as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
    );
  }
}

class NFTAssetModel {
  final String? tokenAddress;
  final String? tokenId;
  final String? contractType;
  final String? name;
  final String? symbol;
  NormalizedMetadata? normalizedMetadata;

  NFTAssetModel(
      {this.tokenAddress,
      this.tokenId,
      this.contractType,
      this.name,
      this.symbol,
      this.normalizedMetadata});

  factory NFTAssetModel.fromJson(Map<String, dynamic> json) {
    return NFTAssetModel(
      tokenAddress: json['token_address'] as String?,
      tokenId: json['token_id'] as String?,
      contractType: json['contract_type'] as String?,
      name: sanitizeNFTText(json["name"] as String?),
      symbol: sanitizeNFTText(json["symbol"] as String?),
      normalizedMetadata: json['normalized_metadata'] != null
          ? new NormalizedMetadata.fromJson(json['normalized_metadata'] as Map<String, dynamic>)
          : null,
    );
  }
}

class NormalizedMetadata {
  final String? name;
  final String? description;
  final String? image;
  NormalizedMetadata({
    this.name,
    this.description,
    this.image,
  });

  factory NormalizedMetadata.fromJson(Map<String, dynamic> json) {
    return NormalizedMetadata(
      name: sanitizeNFTText(json["name"] as String?),
      description: sanitizeNFTText(json["description"] as String?),
      image: json["image"] as String?,
    );
  }

  String? get imageUrl => tryNormalizeIpfsUrl(image);
}
