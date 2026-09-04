
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

  static const List<WalletPresetIconDefinition> all = [
    WalletPresetIconDefinition(
      value: 'heart',
      assetPath: 'assets/new-ui/favorite_icon.svg',
      label: 'Heart',
    ),
    WalletPresetIconDefinition(
      value: 'flower',
      assetPath: 'assets/new-ui/wallet_icons/flower.svg',
      label: 'Flower',
    ),
    WalletPresetIconDefinition(
      value: 'star',
      assetPath: 'assets/new-ui/wallet_icons/star.svg',
      label: 'Star',
    ),
    WalletPresetIconDefinition(
      value: 'cart',
      assetPath: 'assets/new-ui/wallet_icons/cart.svg',
      label: 'Cart',
    ),
    WalletPresetIconDefinition(
      value: 'chess',
      assetPath: 'assets/new-ui/wallet_icons/chess.svg',
      label: 'Chess',
    ),
    WalletPresetIconDefinition(
      value: 'paraglider',
      assetPath: 'assets/new-ui/wallet_icons/paraglider.svg',
      label: 'Paraglider',
    ),
    WalletPresetIconDefinition(
      value: 'tshirt',
      assetPath: 'assets/new-ui/wallet_icons/tshirt.svg',
      label: 'T-Shirt',
    ),
    WalletPresetIconDefinition(
      value: 'piggy_bank',
      assetPath: 'assets/new-ui/wallet_icons/piggy_bank.svg',
      label: 'Piggy Bank',
    ),
    WalletPresetIconDefinition(
      value: 'bank',
      assetPath: 'assets/new-ui/wallet_icons/bank.svg',
      label: 'Bank',
    ),
    WalletPresetIconDefinition(
      value: 'dice',
      assetPath: 'assets/new-ui/wallet_icons/dice.svg',
      label: 'Dice',
    ),
    WalletPresetIconDefinition(
      value: 'motorcycle',
      assetPath: 'assets/new-ui/wallet_icons/motorcycle.svg',
      label: 'Motorcycle',
    ),
    WalletPresetIconDefinition(
      value: 'paper_plane',
      assetPath: 'assets/new-ui/wallet_icons/paper_plane.svg',
      label: 'Paper Plane',
    ),
    WalletPresetIconDefinition(
      value: 'infinity',
      assetPath: 'assets/new-ui/wallet_icons/infinity.svg',
      label: 'Infinity',
    ),
    WalletPresetIconDefinition(
      value: 'shield',
      assetPath: 'assets/new-ui/wallet_icons/shield.svg',
      label: 'Shield',
    ),
    WalletPresetIconDefinition(
      value: 'music_notes',
      assetPath: 'assets/new-ui/wallet_icons/music_notes.svg',
      label: 'Music Notes',
    ),
  ];

  static String? assetPathFor(String value) {
    for (final preset in all) {
      if (preset.value == value) return preset.assetPath;
    }
    return null;
  }
}

