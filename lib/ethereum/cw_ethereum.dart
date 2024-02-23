part of 'ethereum.dart';

class CWEthereum extends Ethereum {
  @override
  List<String> getEthereumWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createEthereumWalletService(Box<WalletInfo> walletInfoSource) =>
      EthereumWalletService(walletInfoSource, client: EthereumClient());

  @override
  WalletCredentials createEthereumNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) =>
      EVMChainNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createEthereumRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
  }) =>
      EVMChainRestoreWalletFromSeedCredentials(name: name, password: password, mnemonic: mnemonic);

  @override
  WalletCredentials createEthereumRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      EVMChainRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  String getAddress(WalletBase wallet) => (wallet as EthereumWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as EthereumWallet).evmChainPrivateKey;
    String stringKey = bytesToHex(privateKeyHolder.privateKey);
    return stringKey;
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as EthereumWallet).evmChainPrivateKey;
    final publicKey = privateKeyInUnitInt.address.hex;
    return publicKey;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getEthereumTransactionPrioritySlow() => EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() => EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializeEthereumTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  Object createEthereumTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  }) =>
      EVMChainTransactionCredentials(
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
        priority: priority as EVMChainTransactionPriority,
        currency: currency,
        feeRate: feeRate,
      );

  Object createEthereumTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  }) =>
      EVMChainTransactionCredentials(
        outputs,
        priority: priority as EVMChainTransactionPriority?,
        currency: currency,
        feeRate: feeRate,
      );

  @override
  int formatterEthereumParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

  @override
  double formatterEthereumAmountToDouble(
      {TransactionInfo? transaction, BigInt? amount, int exponent = 18}) {
    assert(transaction != null || amount != null);

    if (transaction != null) {
      transaction as EVMChainTransactionInfo;
      return transaction.ethAmount / BigInt.from(10).pow(transaction.exponent);
    } else {
      return (amount!) / BigInt.from(10).pow(exponent);
    }
  }

  @override
  List<Erc20Token> getERC20Currencies(WalletBase wallet) {
    final ethereumWallet = wallet as EthereumWallet;
    return ethereumWallet.erc20Currencies;
  }

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) async {
    await (wallet as EthereumWallet).addErc20Token(token as Erc20Token);
  }

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as EthereumWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) async {
    final ethereumWallet = wallet as EthereumWallet;
    return await ethereumWallet.getErc20Token(contractAddress);
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.eth.title) {
      return CryptoCurrency.eth;
    }

    wallet as EthereumWallet;
    return wallet.erc20Currencies
        .firstWhere((element) => transaction.tokenSymbol == element.symbol);
  }

  @override
  void updateEtherscanUsageState(WalletBase wallet, bool isEnabled) {
    (wallet as EthereumWallet).updateScanProviderUsageState(isEnabled);
  }

  @override
  Web3Client? getWeb3Client(WalletBase wallet) {
    return (wallet as EthereumWallet).getWeb3Client();
  }

  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;
}
