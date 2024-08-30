import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';

class WalletListItem {
  const WalletListItem({
    required this.name,
    required this.type,
    required this.key,
    this.isCurrent = false,
    this.isEnabled = true,
    this.isTestnet = false,
    this.onTap,
  });

  final String name;
  final WalletType type;
  final bool isCurrent;
  final dynamic key;
  final bool isEnabled;
  final bool isTestnet;
  final VoidCallback? onTap;
}
