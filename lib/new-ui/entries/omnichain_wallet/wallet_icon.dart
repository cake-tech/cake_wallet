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
}
