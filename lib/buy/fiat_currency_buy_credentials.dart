class FiatCurrencyBuyCredentials {
  final int id;
  final String name;
  final bool buyable;
  final bool sellable;
  final bool cardBuyable;
  final bool cardSellable;
  final bool instantBuyable;
  final bool instantSellable;
  final Map<String, VolumeLimits> limits;

  FiatCurrencyBuyCredentials({
    required this.id,
    required this.name,
    required this.buyable,
    required this.sellable,
    required this.cardBuyable,
    required this.cardSellable,
    required this.instantBuyable,
    required this.instantSellable,
    required this.limits,
  });

  factory FiatCurrencyBuyCredentials.fromJson(Map<String, dynamic> json) {
    return FiatCurrencyBuyCredentials(
      id: json['id'] as int,
      name: json['name'] as String,
      buyable: json['buyable'] as bool,
      sellable: json['sellable'] as bool,
      cardBuyable: json['cardBuyable'] as bool,
      cardSellable: json['cardSellable'] as bool,
      instantBuyable: json['instantBuyable'] as bool,
      instantSellable: json['instantSellable'] as bool,
      limits: (json['limits'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, VolumeLimits.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}

class VolumeLimits {
  final double minVolume;
  final double maxVolume;

  VolumeLimits({
    required this.minVolume,
    required this.maxVolume,
  });

  factory VolumeLimits.fromJson(Map<String, dynamic> json) {
    return VolumeLimits(
      minVolume: (json['minVolume'] as num).toDouble(),
      maxVolume: (json['maxVolume'] as num).toDouble(),
    );
  }
}