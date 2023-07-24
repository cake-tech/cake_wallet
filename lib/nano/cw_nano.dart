part of 'nano.dart';

class CWNano extends Nano {
  @override
  List<String> getNanoWordList(String language) => EthereumMnemonics.englishWordlist;

  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource) =>
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

  Object createEthereumTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  }) =>
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
        currency: currency,
        feeRate: feeRate,
      );

  Object createEthereumTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  }) =>
      EthereumTransactionCredentials(
        outputs,
        priority: priority as EthereumTransactionPriority?,
        currency: currency,
        feeRate: feeRate,
      );

  @override
  int formatterEthereumParseAmount(String amount) => EthereumFormatter.parseEthereumAmount(amount);

  @override
  double formatterEthereumAmountToDouble({required TransactionInfo transaction}) {
    transaction as EthereumTransactionInfo;
    return cryptoAmountToDouble(
        amount: transaction.amount, divider: BigInt.from(10).pow(transaction.exponent).toInt());
  }

  @override
  List<Erc20Token> getERC20Currencies(WalletBase wallet) {
    final ethereumWallet = wallet as EthereumWallet;
    return ethereumWallet.erc20Currencies;
  }

  @override
  Future<void> addErc20Token(WalletBase wallet, Erc20Token token) async =>
      await (wallet as EthereumWallet).addErc20Token(token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, Erc20Token token) async =>
      await (wallet as EthereumWallet).deleteErc20Token(token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) async {
    final ethereumWallet = wallet as EthereumWallet;
    return await ethereumWallet.getErc20Token(contractAddress);
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EthereumTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.eth.title) {
      return CryptoCurrency.eth;
    }

    wallet as EthereumWallet;
    return wallet.erc20Currencies
        .firstWhere((element) => transaction.tokenSymbol == element.symbol);
  }
}
