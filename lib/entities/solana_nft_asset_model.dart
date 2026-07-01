class SolanaNFTAssetModel {
  String? address;
  String? mint;
  String? standard;
  String? name;
  String? symbol;
  String? description;
  String? imageOriginalUrl;
  String? externalUrl;
  String? metadataOriginalUrl;
  String? totalSupply;
  Metaplex? metaplex;
  Collection? collection;
  Contract? contract;

  SolanaNFTAssetModel({
    this.address,
    this.mint,
    this.standard,
    this.name,
    this.symbol,
    this.description,
    this.imageOriginalUrl,
    this.externalUrl,
    this.metadataOriginalUrl,
    this.totalSupply,
    this.metaplex,
    this.collection,
    this.contract,
  });

  factory SolanaNFTAssetModel.fromJson(Map<String, dynamic> json) {
    return SolanaNFTAssetModel(
      address: json['address'] as String?,
      mint: json['mint'] as String?,
      standard: json['standard'] as String?,
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
      description: json['description'] as String?,
      imageOriginalUrl: json['imageOriginalUrl'] as String?,
      externalUrl: json['externalUrl'] as String?,
      metadataOriginalUrl: json['metadataOriginalUrl'] as String?,
      totalSupply: json['totalSupply'] as String?,
      metaplex: json['metaplex'] != null
          ? Metaplex.fromJson(json['metaplex'] as Map<String, dynamic>)
          : null,
      collection: json['collection'] != null
          ? Collection.fromJson(json['collection'] as Map<String, dynamic>)
          : null,
      contract: json['contract'] != null
          ? Contract.fromJson(json['contract'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Metaplex {
  String? metadataUri;
  String? updateAuthority;
  int? sellerFeeBasisPoints;
  int? primarySaleHappened;
  bool? isMutable;
  bool? masterEdition;

  Metaplex(
      {this.metadataUri,
      this.updateAuthority,
      this.sellerFeeBasisPoints,
      this.primarySaleHappened,
      this.isMutable,
      this.masterEdition});

  factory Metaplex.fromJson(Map<String, dynamic> json) {
    return Metaplex(
      metadataUri: json['metadataUri'] as String?,
      updateAuthority: json['updateAuthority'] as String?,
      sellerFeeBasisPoints: json['sellerFeeBasisPoints'] as int?,
      primarySaleHappened: json['primarySaleHappened'] as int?,
      isMutable: json['isMutable'] as bool?,
      masterEdition: json['masterEdition'] as bool?,
    );
  }
}

class Collection {
  String? collectionAddress;
  String? name;
  String? description;
  String? imageOriginalUrl;
  String? externalUrl;
  String? metaplexMint;
  int? sellerFeeBasisPoints;

  Collection(
      {this.collectionAddress,
      this.name,
      this.description,
      this.imageOriginalUrl,
      this.externalUrl,
      this.metaplexMint,
      this.sellerFeeBasisPoints});

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      collectionAddress: json['collectionAddress'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageOriginalUrl: json['imageOriginalUrl'] as String?,
      externalUrl: json['externalUrl'] as String?,
      metaplexMint: json['metaplexMint'] as String?,
      sellerFeeBasisPoints: json['sellerFeeBasisPoints'] as int?,
    );
  }
}

class Contract {
  String? type;
  String? name;
  String? symbol;

  Contract({this.type, this.name, this.symbol});

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      type: json['type'] as String?,
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
    );
  }
}
