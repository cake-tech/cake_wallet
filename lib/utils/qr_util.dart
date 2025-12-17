import 'package:cw_core/wallet_type.dart';

String getQrImage(WalletType type) {
  switch (type) {
    case WalletType.ethereum:
      return 'assets/images/eth_chain_qr.svg';
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
    case WalletType.base:
      return 'assets/images/base_chain_QR.svg';
    case WalletType.arbitrum:
      return 'assets/images/arbitrum_chain_QR.svg';
    case WalletType.minotari:
    case WalletType.banano:
    case WalletType.haven:
    case WalletType.none:
      return 'assets/images/qr-cake.png';
  }
}

String getChainMonoImage(WalletType type) {
  switch (type) {
    case WalletType.ethereum:
      return 'assets/images/eth_chain_mono.svg';
    case WalletType.solana:
      return 'assets/images/sol_chain_mono.svg';
    case WalletType.polygon:
      return 'assets/images/pol_chain_mono.svg';
    case WalletType.tron:
      return 'assets/images/trx_chain_mono.svg';
    case WalletType.zano:
      return 'assets/images/zano_chain_mono.svg';
    case WalletType.base:
      return 'assets/images/base_chain_mono.svg';
    case WalletType.arbitrum:
      return 'assets/images/arbitrum_chain_mono.svg';
    default:
      return 'assets/images/eth_chain_mono.svg';
  }
}
