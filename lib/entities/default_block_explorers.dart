import 'package:cake_wallet/evm/evm.dart';
import 'package:cw_core/wallet_type.dart';

/// The built-in explorer link for a transaction, used when no custom explorer
/// is selected. EVM wallets use the explorer of their selected network
/// ([chainId]) when it has one.
///
/// Lightning and MWEB transactions are handled by their callers, since they
/// only exist on their own explorers.
String defaultTxUrl(WalletType type, String txId, {int? chainId, bool isTestnet = false}) {
  if (chainId != null) {
    final explorerUrl = evm?.getExplorerUrlForChainId(chainId);
    if (explorerUrl != null) {
      return "$explorerUrl/tx/${txId}";
    }
  }

  switch (type) {
    case WalletType.monero:
      return "https://monero.com/tx/${txId}";
    case WalletType.bitcoin:
      return 'https://mempool.cakewallet.com/${isTestnet ? "testnet/" : ""}tx/${txId}';
    case WalletType.litecoin:
      return "https://blockchair.com/litecoin/transaction/${txId}";
    case WalletType.bitcoinCash:
      return "https://blockchair.com/bitcoin-cash/transaction/${txId}";
    case WalletType.haven:
      return "https://explorer.havenprotocol.org/search?value=${txId}";
    case WalletType.ethereum:
      return "https://etherscan.io/tx/${txId}";
    case WalletType.base:
      return "https://basescan.org/tx/${txId}";
    case WalletType.arbitrum:
      return "https://arbiscan.io/tx/${txId}";
    case WalletType.bsc:
      return "https://bscscan.com/tx/${txId}";
    case WalletType.robinhood:
      return "https://robinhoodchain.blockscout.com/tx/${txId}";
    case WalletType.polygon:
      return "https://polygonscan.com/tx/${txId}";
    case WalletType.nano:
      return "https://nanexplorer.com/nano/block/${txId}";
    case WalletType.banano:
      return "https://nanexplorer.com/banano/block/${txId}";
    case WalletType.solana:
      return "https://solscan.io/tx/${txId}";
    case WalletType.tron:
      return "https://tronscan.org/#/transaction/${txId}";
    case WalletType.wownero:
      return "https://explore.wownero.com/tx/${txId}";
    case WalletType.zano:
      return "https://explorer.zano.org/transaction/${txId}";
    case WalletType.decred:
      return 'https://${isTestnet ? "testnet" : "dcrdata"}.decred.org/tx/${txId.split(':')[0]}';
    case WalletType.dogecoin:
      return "https://blockchair.com/dogecoin/transaction/${txId}";
    case WalletType.zcash:
      return "https://blockchair.com/zcash/transaction/${txId}";
    case WalletType.none:
      return "";
  }
}

/// The host of the built-in explorer, for showing it as a choice.
String defaultExplorerHost(WalletType type, {int? chainId}) =>
    Uri.tryParse(defaultTxUrl(type, "0", chainId: chainId))?.host ?? "";
