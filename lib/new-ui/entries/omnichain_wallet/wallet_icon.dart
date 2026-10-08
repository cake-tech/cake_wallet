enum WalletIconType {
  emoji,
  crypto,
  preset,
  image,
}

class WalletIcon {
  const WalletIcon({
    required this.type,
    required this.value,
    required this.colorIndex,
    required this.backgroundEnabled,
  });

  final WalletIconType type;
  final String value;
  final int colorIndex;
  final bool backgroundEnabled;

  WalletIcon copyWith({
    WalletIconType? type,
    String? value,
    int? colorIndex,
    bool? backgroundEnabled,
  }) =>
      WalletIcon(
        type: type ?? this.type,
        value: value ?? this.value,
        colorIndex: colorIndex ?? this.colorIndex,
        backgroundEnabled: backgroundEnabled ?? this.backgroundEnabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletIcon &&
          other.type == type &&
          other.value == value &&
          other.colorIndex == colorIndex &&
          other.backgroundEnabled == backgroundEnabled;

  @override
  int get hashCode => Object.hash(type, value, colorIndex, backgroundEnabled);
}
