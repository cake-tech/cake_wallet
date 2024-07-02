class FiatBuyCredentials {
  final int id;
  final String name;
  final Map<String, VolumeLimits> limits;

  FiatBuyCredentials({
    required this.id,
    required this.name,
    required this.limits,
  });

  factory FiatBuyCredentials.fromJson(Map<String, dynamic> json) {
    return FiatBuyCredentials(
      id: json['id'] as int,
      name: json['name'] as String,
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
    final minVolume = json['minVolume'] is int
        ? (json['minVolume'] as int).toDouble()
        : json['minVolume'] as double?;
    final maxVolume = json['maxVolume'] is int
        ? (json['maxVolume'] as int).toDouble()
        : json['maxVolume'] as double?;

    return VolumeLimits(
      minVolume: minVolume ?? 0.0,
      maxVolume: maxVolume ?? 0.0,
    );
  }
}
