class WalletNFTsResponseModel {
  int? page;
  int? pageSize;

  List<NFTAssetModel>? result;
  String? status;

  WalletNFTsResponseModel({this.page, this.pageSize, this.result, this.status});

  WalletNFTsResponseModel.fromJson(Map<String, dynamic> json) {
    page = json['page'] as int?;
    pageSize = json['page_size'] as int?;

    if (json['result'] != null) {
      result = <NFTAssetModel>[];
      json['result'].forEach((v) {
        result!.add(new NFTAssetModel.fromJson(v as Map<String, dynamic>));
      });
    }
    status = json['status'] as String?;
  }
}

class NFTAssetModel {
  String? tokenAddress;
  String? tokenId;
  String? amount;
  String? ownerOf;
  String? tokenHash;
  String? blockNumberMinted;
  String? blockNumber;
  bool? possibleSpam;
  String? contractType;
  String? name;
  String? symbol;
  String? tokenUri;
  String? metadata;
  String? lastTokenUriSync;
  String? lastMetadataSync;
  NormalizedMetadata? normalizedMetadata;
  bool? verifiedCollection;

  NFTAssetModel(
      {this.tokenAddress,
      this.tokenId,
      this.amount,
      this.ownerOf,
      this.tokenHash,
      this.blockNumberMinted,
      this.blockNumber,
      this.possibleSpam,
      this.contractType,
      this.name,
      this.symbol,
      this.tokenUri,
      this.metadata,
      this.lastTokenUriSync,
      this.lastMetadataSync,
      this.normalizedMetadata,
      this.verifiedCollection});

  NFTAssetModel.fromJson(Map<String, dynamic> json) {
    tokenAddress = json['token_address'] as String?;
    tokenId = json['token_id'] as String?;
    amount = json['amount'] as String?;
    ownerOf = json['owner_of'] as String?;
    tokenHash = json['token_hash'] as String?;
    blockNumberMinted = json['block_number_minted'] as String?;
    blockNumber = json['block_number'] as String?;
    possibleSpam = json['possible_spam'] as bool?;
    contractType = json['contract_type'] as String?;
    name = json['name'] as String?;
    symbol = json['symbol'] as String?;
    tokenUri = json['token_uri'] as String?;
    metadata = json['metadata'] as String?;
    lastTokenUriSync = json['last_token_uri_sync'] as String?;
    lastMetadataSync = json['last_metadata_sync'] as String?;
    normalizedMetadata = json['normalized_metadata'] != null
        ? new NormalizedMetadata.fromJson(json['normalized_metadata'] as Map<String, dynamic>)
        : null;
    verifiedCollection = json['verified_collection'] as bool?;
  }
}

class NormalizedMetadata {
  String? name;
  String? description;
  String? animationUrl;
  String? externalLink;
  String? image;
  List<Attributes>? attributes;

  NormalizedMetadata(
      {this.name,
      this.description,
      this.animationUrl,
      this.externalLink,
      this.image,
      this.attributes});

  NormalizedMetadata.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    description = json['description'] as String?;
    animationUrl = json['animation_url'] as String?;
    externalLink = json['external_link'] as String?;
    image = json['image'] as String?;
    if (json['attributes'] != null) {
      attributes = <Attributes>[];
      json['attributes'].forEach((v) {
        attributes!.add(new Attributes.fromJson(v as Map<String, dynamic>));
      });
    }
  }

  String? get imageUrl {
    if (image == null) return image;

    if (!image!.contains('ipfs')) return image;

    // IPFS public gateway provided by Cloudflare is https://cloudflare-ipfs.com/ipfs/
    //
    // Here is an example of an ipfs image link:
    //
    // [ipfs://bafkreia2i2ctfexpovgzfff66wqhbmwwpvqjvozan7ioifzcnq76jharwu]

    const String ipfsPublicGateway = 'https://cloudflare-ipfs.com/ipfs/';

    final ipfsPath = image?.split('//')[1];

    final imageLink = '$ipfsPublicGateway$ipfsPath';

    return imageLink;
  }
}

class Attributes {
  String? traitType;
  String? value;
  int? traitCount;

  Attributes({this.traitType, this.value, this.traitCount});

  Attributes.fromJson(Map<String, dynamic> json) {
    traitType = json['trait_type'] as String?;
    value = json['value'] as String?;
    traitCount = json['trait_count'] as int?;
  }
}
