import 'package:cw_core/wallet_type.dart';

bool isEVMCompatibleChain(WalletType walletType) {
  switch (walletType) {
    case WalletType.polygon:
    case WalletType.ethereum:
      return true;
    default:
      return false;
  }
}
