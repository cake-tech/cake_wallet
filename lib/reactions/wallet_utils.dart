import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

/// Whether [wallet] may share a wallet group with wallets of other types
/// (the add-to-group picker rule). Hardware wallets are not checked here.
Future<bool> canShareWalletGroup(WalletInfo wallet) async {
  if (!isBIP39Wallet(wallet.type) || wallet.isNonSeedWallet) return false;

  final derivationType = (await wallet.getDerivationInfo()).derivationType;
  switch (wallet.type) {
    case WalletType.nano:
      return derivationType != DerivationType.nano;
    case WalletType.bitcoin:
    case WalletType.litecoin:
      return derivationType != DerivationType.electrum;
    case WalletType.monero:
    case WalletType.zano:
      return derivationType == DerivationType.bip39;
    case WalletType.decred:
      return derivationType == DerivationType.bip39 ||
          derivationType == DerivationType.unknown;
    default:
      return true;
  }
}

bool isBIP39Wallet(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
    case WalletType.polygon:
    case WalletType.base:
    case WalletType.arbitrum:
    case WalletType.bsc:
    case WalletType.robinhood:
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
    case WalletType.zano:
    case WalletType.decred:
      return true;
    case WalletType.wownero:
    case WalletType.haven:
    case WalletType.none:
      return false;
  }
}

bool isElectrumWallet(WalletType walletType) {
  switch (walletType) {
    case WalletType.bitcoin:
    case WalletType.litecoin:
    case WalletType.bitcoinCash:
    case WalletType.dogecoin:
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
    case WalletType.bsc:
    case WalletType.robinhood:
      return true;
    default:
      return false;
  }
}

String tokenStandardFor(WalletType walletType) {
  switch (walletType) {
    case WalletType.ethereum:
    case WalletType.polygon:
    case WalletType.arbitrum:
    case WalletType.base:
    case WalletType.robinhood:
      return 'ERC-20';
    case WalletType.bsc:
      return 'BEP-20';
    case WalletType.solana:
      return 'SPL';
    case WalletType.tron:
      return 'TRC-20';
    default:
      return walletTypeToString(walletType);
  }
}
