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

  Object createEthereumTransactionCredentials(List<Output> outputs,
          {required TransactionPriority priority, int? feeRate}) =>
      EthereumTransactionCredentials(
        outputs
            .map((out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount))
            .toList(),
        priority: priority as EthereumTransactionPriority,
        feeRate: feeRate,
      );

  Object createEthereumTransactionCredentialsRaw(List<OutputInfo> outputs,
          {TransactionPriority? priority, required int feeRate}) =>
      EthereumTransactionCredentials(
        outputs,
        priority: priority as EthereumTransactionPriority,
        feeRate: feeRate,
      );

  @override
  int formatterEthereumParseAmount(String amount) => EthereumFormatter.parseEthereumAmount(amount);
}
