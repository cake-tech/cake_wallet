part of 'ethereum.dart';

class CWEthereum extends Ethereum {
  @override
  List<String> getEthereumWordList(String language) {
    return EthereumMnemonics.englishWordlist;
  }

  WalletService createEthereumWalletService(Box<WalletInfo> walletInfoSource) {
    return EthereumWalletService(walletInfoSource);
  }
}
