  import 'package:cw_core/wallet_type.dart';

bool isBIP39Wallet(WalletType walletType) {
    switch (walletType) {
      case WalletType.ethereum:
      case WalletType.polygon:
        return true;
      default:
        return false;
    }
  }