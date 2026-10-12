class WalletPresetIconDefinition {
  const WalletPresetIconDefinition({
    required this.value,
    required this.assetPath,
    required this.label,
  });

  final String value;
  final String assetPath;
  final String label;
}

class WalletPresetIcons {
  const WalletPresetIcons._();

  static const defaultValue = "wallet";

  static const List<WalletPresetIconDefinition> all = [
    WalletPresetIconDefinition(
      value: defaultValue,
      assetPath: "assets/new-ui/wallets.svg",
      label: "Wallet",
    ),
    WalletPresetIconDefinition(
      value: "heart",
      assetPath: "assets/new-ui/wallet_icons/favorite_icon.svg",
      label: "Heart",
    ),
    WalletPresetIconDefinition(
      value: "flower",
      assetPath: "assets/new-ui/wallet_icons/flower.svg",
      label: "Flower",
    ),
    WalletPresetIconDefinition(
      value: "star",
      assetPath: "assets/new-ui/wallet_icons/star.svg",
      label: "Star",
    ),
    WalletPresetIconDefinition(
      value: "cart",
      assetPath: "assets/new-ui/wallet_icons/cart.svg",
      label: "Cart",
    ),
    WalletPresetIconDefinition(
      value: "chess",
      assetPath: "assets/new-ui/wallet_icons/chess.svg",
      label: "Chess",
    ),
    WalletPresetIconDefinition(
      value: "parasol",
      assetPath: "assets/new-ui/wallet_icons/parasol.svg",
      label: "Parasol",
    ),
    WalletPresetIconDefinition(
      value: "tshirt",
      assetPath: "assets/new-ui/wallet_icons/tshirt.svg",
      label: "T-Shirt",
    ),
    WalletPresetIconDefinition(
      value: "piggy_bank",
      assetPath: "assets/new-ui/wallet_icons/piggy_bank.svg",
      label: "Piggy Bank",
    ),
    WalletPresetIconDefinition(
      value: "bank",
      assetPath: "assets/new-ui/wallet_icons/bank.svg",
      label: "Bank",
    ),
    WalletPresetIconDefinition(
      value: "planet",
      assetPath: "assets/new-ui/wallet_icons/planet.svg",
      label: "Planet",
    ),
    WalletPresetIconDefinition(
      value: "motorcycle",
      assetPath: "assets/new-ui/wallet_icons/motorcycle.svg",
      label: "Motorcycle",
    ),
    WalletPresetIconDefinition(
      value: "plane",
      assetPath: "assets/new-ui/wallet_icons/plane.svg",
      label: "Plane",
    ),
    WalletPresetIconDefinition(
      value: "mask",
      assetPath: "assets/new-ui/wallet_icons/mask.svg",
      label: "Mask",
    ),
    WalletPresetIconDefinition(
      value: "shield",
      assetPath: "assets/new-ui/wallet_icons/shield.svg",
      label: "Shield",
    ),
    WalletPresetIconDefinition(
      value: "music_notes",
      assetPath: "assets/new-ui/wallet_icons/music_notes.svg",
      label: "Music Notes",
    ),
  ];

  static String? assetPathFor(String value) {
    for (final preset in all) {
      if (preset.value == value) return preset.assetPath;
    }
    return null;
  }
}
