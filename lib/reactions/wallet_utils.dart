import 'package:cw_core/wallet_type.dart';

bool isBIP39Wallet(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
    case WalletType.polygon:
    case WalletType.base:
    case WalletType.arbitrum:
    case WalletType.solana:
    case WalletType.tron:
    case WalletType.bitcoin:
    case WalletType.litecoin:
    case WalletType.bitcoinCash:
    case WalletType.nano:
    case WalletType.banano:
    case WalletType.monero:
    case WalletType.dogecoin:
    case WalletType.zcash:
      return true;
    case WalletType.wownero:
    case WalletType.haven:
    case WalletType.zano:
    case WalletType.decred:
    case WalletType.none:
      return false;
  }
}

bool isElectrumWallet(WalletType walletType) {
  switch (walletType) {
    case WalletType.bitcoin:
    case WalletType.litecoin:
    case WalletType.bitcoinCash:
      return true;
    default:
      return false;
  }
}

bool hasTokens(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
    case WalletType.polygon:
    case WalletType.solana:
    case WalletType.tron:
    case WalletType.zano:
    case WalletType.base:
    case WalletType.arbitrum:
      return true;
    default:
      return false;
  }
}