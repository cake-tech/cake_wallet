class AssetBuyCredentials {
  final int id;
  final String name;
  final String? chainId;
  final String uniqueName;
  final String description;
  final String type;
  final String category;
  final String dexName;
  final String feeTier;
  final bool comingSoon;
  final bool buyable;
  final bool sellable;
  final bool instantBuyable;
  final bool instantSellable;
  final bool cardBuyable;
  final bool cardSellable;
  final String blockchain;
  final int? sortOrder;
  final Limits limits;

  AssetBuyCredentials({
    required this.id,
    required this.name,
    required this.chainId,
    required this.uniqueName,
    required this.description,
    required this.type,
    required this.category,
    required this.dexName,
    required this.feeTier,
    required this.comingSoon,
    required this.buyable,
    required this.sellable,
    required this.instantBuyable,
    required this.instantSellable,
    required this.cardBuyable,
    required this.cardSellable,
    required this.blockchain,
    required this.sortOrder,
    required this.limits,
  });

  factory AssetBuyCredentials.fromJson(Map<String, dynamic> json) {
    return AssetBuyCredentials(
      id: json['id'] as int,
      name: json['name'] as String,
      chainId: json['chainId'] as String?,
      uniqueName: json['uniqueName'] as String ,
      description: json['description'] as String,
      type: json['type'] as String,
      category: json['category'] as String ,
      dexName: json['dexName'] as String,
      feeTier: json['feeTier'] as String,
      comingSoon: json['comingSoon'] as bool ,
      buyable: json['buyable'] as bool,
      sellable: json['sellable'] as bool,
      instantBuyable: json['instantBuyable'] as bool,
      instantSellable: json['instantSellable'] as bool,
      cardBuyable: json['cardBuyable'] as bool,
      cardSellable: json['cardSellable'] as bool,
      blockchain: json['blockchain'] as String,
      sortOrder: json['sortOrder'] as int?,
      limits: Limits.fromJson(json['limits'] as Map<String, dynamic>),
    );
  }
}

class Limits {
  final double minVolume;
  final double maxVolume;

  Limits({required this.minVolume, required this.maxVolume});

  factory Limits.fromJson(Map<String, dynamic> json) {
    return Limits(
      minVolume: json['minVolume'] as double,
      maxVolume: json['maxVolume'] as double,
    );
  }
}