part of 'arbitrum.dart';

class CWArbitrum extends Arbitrum {
  @override
  List<String> getArbitrumWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createArbitrumWalletService(Box<WalletInfo> walletInfoSource, bool isDirect) =>
      ArbitrumWalletService(walletInfoSource, isDirect, client: ArbitrumClient());

  @override
  WalletCredentials createArbitrumNewWalletCredentials({
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
  WalletCredentials createArbitrumRestoreWalletFromSeedCredentials({
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
  WalletCredentials createArbitrumRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      EVMChainRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  WalletCredentials createArbitrumHardwareWalletCredentials({
    required String name,
    required HardwareAccountData hwAccountData,
    WalletInfo? walletInfo,
  }) =>
      EVMChainRestoreWalletFromHardware(
        name: name,
        hwAccountData: hwAccountData,
        walletInfo: walletInfo,
      );

  @override
  String getAddress(WalletBase wallet) => (wallet as ArbitrumWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as ArbitrumWallet).evmChainPrivateKey;
    if (privateKeyHolder is EthPrivateKey) return bytesToHex(privateKeyHolder.privateKey);
    return "";
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as ArbitrumWallet).evmChainPrivateKey;
    return privateKeyInUnitInt.address.hex;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getArbitrumTransactionPrioritySlow() => EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() => EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializeArbitrumTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  Object createArbitrumTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  }) =>
      EVMChainTransactionCredentials(
        outputs
            .map(
              (out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmount,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
                formattedCryptoAmount: out.formattedCryptoAmount,
              ),
            )
            .toList(),
        priority: priority as EVMChainTransactionPriority,
        currency: currency,
        feeRate: feeRate,
      );

  Object createArbitrumTransactionCredentialsRaw(
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
  int formatterArbitrumParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

  @override
  double formatterArbitrumAmountToDouble({
    TransactionInfo? transaction,
    BigInt? amount,
    int exponent = 18,
  }) {
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
      (wallet as ArbitrumWallet).erc20Currencies;

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as ArbitrumWallet).addErc20Token(token as Erc20Token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as ArbitrumWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token) =>
      (wallet as ArbitrumWallet).removeTokenTransactionsInHistory(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) =>
      (wallet as ArbitrumWallet).getErc20Token(contractAddress, 'arbitrum');

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.arbEth.title ||
        transaction.tokenSymbol == "ARB") {
      return CryptoCurrency.arbEth;
    }

    wallet as ArbitrumWallet;

    return wallet.erc20Currencies.firstWhere(
      (element) =>
          transaction.contractAddress?.toLowerCase() == element.contractAddress?.toLowerCase(),
    );
  }

  @override
  void updateArbitrumScanUsageState(WalletBase wallet, bool isEnabled) =>
      (wallet as ArbitrumWallet).updateScanProviderUsageState(isEnabled);

  @override
  Web3Client? getWeb3Client(WalletBase wallet) => (wallet as ArbitrumWallet).getWeb3Client();

  @override
  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;

  @override
  Future<PendingTransaction> createTokenApproval(
    WalletBase wallet,
    BigInt amount,
    String spender,
    CryptoCurrency token,
    TransactionPriority priority,
  ) =>
      (wallet as EVMChainWallet).createApprovalTransaction(
        amount,
        spender,
        token,
        priority as EVMChainTransactionPriority,
        "ARB",
      );

  @override
  void setHardwareWalletService(WalletBase wallet, HardwareWalletService service) {
    if (service is EVMChainLedgerService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmLedgerCredentials).setLedgerConnection(
          service.ledgerConnection, wallet.walletInfo.derivationInfo?.derivationPath);
    } else if (service is EVMChainBitboxService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmBitboxCredentials)
          .setBitbox(service.manager, wallet.walletInfo.derivationInfo?.derivationPath);
    }
  }

  @override
  HardwareWalletService getLedgerHardwareWalletService(ledger.LedgerConnection connection) =>
      EVMChainLedgerService(connection);

  @override
  HardwareWalletService getBitboxHardwareWalletService(bitbox.BitboxManager manager) =>
      EVMChainBitboxService(manager, chainId: 42161);

  @override
  List<String> getDefaultTokenContractAddresses() => DefaultArbitrumErc20Tokens()
      .initialArbitrumErc20Tokens
      .map((e) => e.contractAddress)
      .toList();

  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final arbitrumWallet = wallet as ArbitrumWallet;
    return arbitrumWallet.erc20Currencies.any(
      (element) => element.contractAddress.toLowerCase() == contractAddress.toLowerCase(),
    );
  }
}
