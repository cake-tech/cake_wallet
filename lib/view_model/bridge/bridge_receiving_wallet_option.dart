import 'package:cw_core/wallet_info.dart';

class BridgeReceivingWalletOption {
  const BridgeReceivingWalletOption({
    required this.walletInfo,
    required this.isCurrent,
    this.groupLabel,
  });

  final WalletInfo walletInfo;
  final bool isCurrent;

  final String? groupLabel;

  String get name => walletInfo.name;
  String get address => walletInfo.address;
}
