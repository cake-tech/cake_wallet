part of 'gnosis.dart';

class CWGnosis extends Gnosis {
  @override
  List<String> getGnosisWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createGnosisWalletService(Box<WalletInfo> walletInfoSource, bool isDirect) =>
      GnosisWalletService(walletInfoSource, isDirect, client: GnosisClient());

  @override
  WalletCredentials createGnosisNewWalletCredentials({
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
  WalletCredentials createGnosisRestoreWalletFromSeedCredentials({
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
  WalletCredentials createGnosisRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      EVMChainRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  WalletCredentials createGnosisHardwareWalletCredentials({
    required String name,
    required HardwareAccountData hwAccountData,
    WalletInfo? walletInfo,
  }) =>
      EVMChainRestoreWalletFromHardware(
          name: name, hwAccountData: hwAccountData, walletInfo: walletInfo);

  @override
  String getAddress(WalletBase wallet) => (wallet as GnosisWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as GnosisWallet).evmChainPrivateKey;
    if (privateKeyHolder is EthPrivateKey) return bytesToHex(privateKeyHolder.privateKey);
    return "";
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as GnosisWallet).evmChainPrivateKey;
    final publicKey = privateKeyInUnitInt.address.hex;
    return publicKey;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getGnosisTransactionPrioritySlow() => EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() => EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializeGnosisTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  Object createGnosisTransactionCredentials(
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

  Object createGnosisTransactionCredentialsRaw(
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
  int formatterGnosisParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

  @override
  double formatterGnosisAmountToDouble(
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
    final polygonWallet = wallet as GnosisWallet;
    return polygonWallet.erc20Currencies;
  }

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as GnosisWallet).addErc20Token(token as Erc20Token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as GnosisWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as GnosisWallet).removeTokenTransactionsInHistory(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) async {
    final polygonWallet = wallet as GnosisWallet;
    return await polygonWallet.getErc20Token(contractAddress, 'polygon');
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.maticpoly.title ||
        transaction.tokenSymbol == "MATIC") {
      return CryptoCurrency.maticpoly;
    }

    wallet as GnosisWallet;

    return wallet.erc20Currencies.firstWhere(
      (element) => transaction.tokenSymbol.toLowerCase() == element.symbol.toLowerCase(),
    );
  }

  @override
  void updateGnosisScanUsageState(WalletBase wallet, bool isEnabled) {
    (wallet as GnosisWallet).updateScanProviderUsageState(isEnabled);
  }

  @override
  Web3Client? getWeb3Client(WalletBase wallet) {
    return (wallet as GnosisWallet).getWeb3Client();
  }

  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;

  @override
  void setLedgerConnection(
      WalletBase wallet, ledger.LedgerConnection connection) {
    ((wallet as EVMChainWallet).evmChainPrivateKey as EvmLedgerCredentials)
        .setLedgerConnection(
        connection, wallet.walletInfo.derivationInfo?.derivationPath);
  }

  @override
  Future<List<HardwareAccountData>> getHardwareWalletAccounts(LedgerViewModel ledgerVM,
      {int index = 0, int limit = 5}) async {
    final hardwareWalletService = EVMChainHardwareWalletService(ledgerVM.connection);
    try {
      return await hardwareWalletService.getAvailableAccounts(index: index, limit: limit);
    } catch (err) {
      printV(err);
      throw err;
    }
  }
  
  @override
  List<String> getDefaultTokenContractAddresses() {
    return DefaultGnosisErc20Tokens().initialGnosisErc20Tokens.map((e) => e.contractAddress).toList();
  }
}
