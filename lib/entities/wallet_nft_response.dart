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
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      normalizedMetadata: json['normalized_metadata'] != null
          ? new NormalizedMetadata.fromJson(
              json['normalized_metadata'] as Map<String, dynamic>)
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
      name: json['name'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
    );

  }

  String? get imageUrl {
    if (image == null) return image;

    if (image!.contains('ipfs.io')) return image;

    if (!image!.contains('ipfs')) return image;

    // IPFS public gateway provided by Cloudflare is https://cloudflare-ipfs.com/ipfs/
    //
    // Here is an example of an ipfs image link:
    //
    // [ipfs://bafkreia2i2ctfexpovgzfff66wqhbmwwpvqjvozan7ioifzcnq76jharwu]

    //https://ipfs.io/ipfs/QmTRcRXo6cXByjHYHTVxGpag6vpocrG3rxjPC9PxKAArR9/1620.png

    const String ipfsPublicGateway = 'https://cloudflare-ipfs.com/ipfs/';

    final ipfsPath = image?.split('//')[1];

    final imageLink = '$ipfsPublicGateway$ipfsPath';

    return imageLink;
  }
}
