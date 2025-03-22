import 'package:cw_core/wallet_type.dart';

class WalletListItem {
  const WalletListItem({
    required this.name,
    required this.type,
    required this.key,
    required this.isHardware,
    this.isCurrent = false,
    this.isEnabled = true,
    this.isTestnet = false,
  });

  final String name;
  final WalletType type;
  final bool isCurrent;
  final dynamic key;
  final bool isEnabled;
  final bool isTestnet;
  final bool isHardware;
}
