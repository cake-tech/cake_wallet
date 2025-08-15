part of 'ethereum.dart';

class CWEthereum extends Ethereum {
  @override
  List<String> getEthereumWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createEthereumWalletService(Box<WalletInfo> walletInfoSource, bool isDirect) =>
      EthereumWalletService(walletInfoSource, isDirect, client: EthereumClient());

  @override
  WalletCredentials createEthereumNewWalletCredentials({
    required String name,
    String? mnemonic,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
  }) =>
      EVMChainNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createEthereumRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      EVMChainRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createEthereumRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      EVMChainRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  WalletCredentials createEthereumHardwareWalletCredentials({
    required String name,
    required HardwareAccountData hwAccountData,
    WalletInfo? walletInfo,
  }) =>
      EVMChainRestoreWalletFromHardware(
          name: name, hwAccountData: hwAccountData, walletInfo: walletInfo);

  @override
  String getAddress(WalletBase wallet) => (wallet as EthereumWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as EthereumWallet).evmChainPrivateKey;
    if (privateKeyHolder is EthPrivateKey) return bytesToHex(privateKeyHolder.privateKey);
    return "";
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as EthereumWallet).evmChainPrivateKey;
    return privateKeyInUnitInt.address.hex;
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
                formattedCryptoAmount: out.formattedCryptoAmount,
                memo: out.memo))
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
  List<Erc20Token> getERC20Currencies(WalletBase wallet) =>
      (wallet as EthereumWallet).erc20Currencies;

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as EthereumWallet).addErc20Token(token as Erc20Token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as EthereumWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token) =>
      (wallet as EthereumWallet).removeTokenTransactionsInHistory(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) =>
      (wallet as EthereumWallet).getErc20Token(contractAddress, 'eth');

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.eth.title) {
      return CryptoCurrency.eth;
    }

    wallet as EthereumWallet;

    return wallet.erc20Currencies.firstWhere(
      (element) => transaction.tokenSymbol == element.symbol,
    );
  }

  @override
  void updateEtherscanUsageState(WalletBase wallet, bool isEnabled) =>
      (wallet as EthereumWallet).updateScanProviderUsageState(isEnabled);

  @override
  Web3Client? getWeb3Client(WalletBase wallet) => (wallet as EthereumWallet).getWeb3Client();

  @override
  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;

  @override
  void setLedgerConnection(WalletBase wallet, ledger.LedgerConnection connection) {
    ((wallet as EVMChainWallet).evmChainPrivateKey as EvmLedgerCredentials)
        .setLedgerConnection(connection, wallet.walletInfo.derivationInfo?.derivationPath);
  }

  @override
  HardwareWalletService getHardwareWalletService(LedgerViewModel ledgerVM) =>
      EVMChainLedgerService(ledgerVM.connection);

  @override
  List<String> getDefaultTokenContractAddresses() {
    return DefaultEthereumErc20Tokens().initialErc20Tokens.map((e) => e.contractAddress).toList();
  }


  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final ethereumWallet = wallet as EthereumWallet;
    return ethereumWallet.erc20Currencies.any((element) => element.contractAddress.toLowerCase() == contractAddress.toLowerCase());
  }

  Future<PendingTransaction> createTokenApproval(WalletBase wallet, BigInt amount, String spender,
          CryptoCurrency token, TransactionPriority priority) =>
      (wallet as EVMChainWallet).createApprovalTransaction(
          amount, spender, token, priority as EVMChainTransactionPriority, "ETH");

  // Integrations
  @override
  Future<BigInt> getDEuroSavingsBalance(WalletBase wallet) =>
      DEuro(wallet as EthereumWallet).savingsBalance;

  @override
  Future<BigInt> getDEuroAccruedInterest(WalletBase wallet) =>
      DEuro(wallet as EthereumWallet).accruedInterest;

  @override
  Future<BigInt> getDEuroInterestRate(WalletBase wallet) =>
      DEuro(wallet as EthereumWallet).interestRate;

  @override
  Future<BigInt> getDEuroSavingsApproved(WalletBase wallet) =>
      DEuro(wallet as EthereumWallet).approvedBalance;

  @override
  Future<PendingTransaction> addDEuroSaving(
          WalletBase wallet, BigInt amount, TransactionPriority priority) =>
      DEuro(wallet as EthereumWallet)
          .depositSavings(amount, priority as EVMChainTransactionPriority);

  @override
  Future<PendingTransaction> removeDEuroSaving(
          WalletBase wallet, BigInt amount, TransactionPriority priority) =>
      DEuro(wallet as EthereumWallet)
          .withdrawSavings(amount, priority as EVMChainTransactionPriority);

  @override
  Future<PendingTransaction> reinvestDEuroInterest(
          WalletBase wallet, TransactionPriority priority) =>
      DEuro(wallet as EthereumWallet).reinvestInterest(priority as EVMChainTransactionPriority);

  @override
  Future<PendingTransaction> enableDEuroSaving(WalletBase wallet, TransactionPriority priority) =>
      DEuro(wallet as EthereumWallet).enableSavings(priority as EVMChainTransactionPriority);
}
