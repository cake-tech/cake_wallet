part of 'ethereum.dart';

class CWEthereum extends Ethereum {
  @override
  List<String> getEthereumWordList(String language) => EthereumMnemonics.englishWordlist;

  WalletService createEthereumWalletService(Box<WalletInfo> walletInfoSource) =>
      EthereumWalletService(walletInfoSource);

  @override
  WalletCredentials createEthereumNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) {
    return EthereumNewWalletCredentials(name: name, walletInfo: walletInfo);
  }

  String getAddress(WalletBase wallet) => (wallet as EthereumWallet).walletAddresses.address;
}
