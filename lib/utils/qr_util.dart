import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cw_core/wallet_type.dart';

String getQrImage(WalletType type, {int? selectedChainId}) {
  if (isEVMCompatibleChain(type) && selectedChainId != null) {
    switch (selectedChainId) {
      case 1:
        return 'assets/images/eth_chain_qr.svg';
      case 137:
        return 'assets/images/pol_chain_qr.svg';
      case 8453:
        return 'assets/images/base_chain_QR.svg';
      case 42161:
        return 'assets/images/arbitrum_chain_QR.svg';
      default:
        return 'assets/images/eth_chain_qr.svg';
    }
  }
  switch (type) {
    case WalletType.solana:
      return 'assets/images/sol_chain_qr.svg';
    case WalletType.polygon:
      return 'assets/images/pol_chain_qr.svg';
    case WalletType.tron:
      return 'assets/images/trx_chain_qr.svg';
    case WalletType.zano:
      return 'assets/images/zano_chain_qr.svg';
    case WalletType.monero:
      return 'assets/images/xmr_chain_qr.svg';
    case WalletType.wownero:
      return 'assets/images/wow_chain_qr.svg';
    case WalletType.bitcoin:
      return 'assets/images/btc_chain_qr.svg';
    case WalletType.litecoin:
      return 'assets/images/ltc_chain_qr.svg';
    case WalletType.bitcoinCash:
      return 'assets/images/bch_chain_qr.svg';
    case WalletType.nano:
      return 'assets/images/xno_chain_qr.svg';
    case WalletType.decred:
      return 'assets/images/dcr_chain_qr.svg';
    case WalletType.dogecoin:
      return 'assets/images/doge_chain_qr.svg';
    case WalletType.banano:
    case WalletType.haven:
    case WalletType.none:
    default:
      return 'assets/images/qr-cake.png';
  }
}

String getChainMonoImage(WalletType type, {int? selectedChainId}) {
  if (isEVMCompatibleChain(type) && selectedChainId != null) {
    switch (selectedChainId) {
      case 1:
        return 'assets/images/eth_chain_mono.svg';
      case 137:
        return 'assets/images/pol_chain_mono.svg';
      case 8453:
        return 'assets/images/base_chain_mono.svg';
      case 42161:
        return 'assets/images/arbitrum_chain_mono.svg';
      default:
        return 'assets/images/eth_chain_mono.svg';
    }
  }

  switch (type) {
    case WalletType.solana:
      return 'assets/images/sol_chain_mono.svg';
    case WalletType.polygon:
      return 'assets/images/pol_chain_mono.svg';
    case WalletType.tron:
      return 'assets/images/trx_chain_mono.svg';
    case WalletType.zano:
      return 'assets/images/zano_chain_mono.svg';
    default:
      return 'assets/images/eth_chain_mono.svg';
  }
}
