import 'package:cw_core/wallet_type.dart';

bool isBIP39Wallet(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
    case WalletType.polygon:
    case WalletType.base:
    case WalletType.solana:
    case WalletType.tron:
    case WalletType.bitcoin:
    case WalletType.litecoin:
    case WalletType.bitcoinCash:
    case WalletType.nano:
    case WalletType.banano:
    case WalletType.monero:
    case WalletType.dogecoin:
      return true;
    case WalletType.wownero:
    case WalletType.haven:
    case WalletType.zano:
    case WalletType.decred:
    case WalletType.none:
      return false;
  }
}

bool onlyBIP39Selected(List<WalletType> types) {
  for (var type in types) {
    if (!isBIP39Wallet(type)) return false;
  }
  return true;
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
      return true;
    default:
      return false;
  }
}