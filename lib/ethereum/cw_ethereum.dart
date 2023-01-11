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
  }) =>
      EthereumNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createEthereumRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
  }) =>
      EthereumRestoreWalletFromSeedCredentials(name: name, password: password, mnemonic: mnemonic);

  @override
  String getAddress(WalletBase wallet) => (wallet as EthereumWallet).walletAddresses.address;

  @override
  TransactionPriority getDefaultTransactionPriority() => EthereumTransactionPriority.medium;

  @override
  List<TransactionPriority> getTransactionPriorities() => EthereumTransactionPriority.all;

  @override
  TransactionPriority deserializeEthereumTransactionPriority(int raw) =>
      EthereumTransactionPriority.deserialize(raw: raw);

  @override
  int getEstimatedFee(Object wallet, TransactionPriority priority) {
    final ethereumWallet = wallet as EthereumWallet;
    return ethereumWallet.feeRate(priority);
  }
}
