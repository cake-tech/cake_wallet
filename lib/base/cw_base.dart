part of 'base.dart';

class CWBase extends Base {
  @override
  List<String> getBaseWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createBaseWalletService(bool isDirect) =>
      BaseWalletService(isDirect, client: BaseClient());

  @override
  WalletCredentials createBaseNewWalletCredentials({
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
  WalletCredentials createBaseRestoreWalletFromSeedCredentials({
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
  WalletCredentials createBaseRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      EVMChainRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  WalletCredentials createBaseHardwareWalletCredentials({
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
  String getAddress(WalletBase wallet) => (wallet as BaseWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as BaseWallet).evmChainPrivateKey;
    if (privateKeyHolder is EthPrivateKey) return bytesToHex(privateKeyHolder.privateKey);
    return "";
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as BaseWallet).evmChainPrivateKey;
    return privateKeyInUnitInt.address.hex;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getBaseTransactionPrioritySlow() => EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() => EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializeBaseTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  Object createBaseTransactionCredentials(
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

  Object createBaseTransactionCredentialsRaw(
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
  int formatterBaseParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

  @override
  double formatterBaseAmountToDouble({
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
  List<Erc20Token> getERC20Currencies(WalletBase wallet) => (wallet as BaseWallet).erc20Currencies;

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as BaseWallet).addErc20Token(token as Erc20Token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as BaseWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token) =>
      (wallet as BaseWallet).removeTokenTransactionsInHistory(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) =>
      (wallet as BaseWallet).getErc20Token(contractAddress, 'base');

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.baseEth.title ||
        transaction.tokenSymbol == "BASE") {
      return CryptoCurrency.baseEth;
    }

    wallet as BaseWallet;

    return wallet.erc20Currencies.firstWhere(
      (element) =>
          transaction.contractAddress?.toLowerCase() == element.contractAddress?.toLowerCase(),
    );
  }

  @override
  void updateBaseScanUsageState(WalletBase wallet, bool isEnabled) =>
      (wallet as BaseWallet).updateScanProviderUsageState(isEnabled);

  @override
  Web3Client? getWeb3Client(WalletBase wallet) => (wallet as BaseWallet).getWeb3Client();

  @override
  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;

  @override
  Future<bool> isApprovalRequired(
          WalletBase wallet, String tokenContract, String spender, BigInt requiredAmount) =>
      (wallet as EVMChainWallet).isApprovalRequired(tokenContract, spender, requiredAmount);

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
        "BASE",
      );

  @override
  Future<PendingTransaction> createRawCallDataTransaction(WalletBase wallet, String to,
          String dataHex, BigInt valueWei, TransactionPriority priority) =>
      (wallet as EVMChainWallet).createCallDataTransaction(
          to, dataHex, valueWei, priority as EVMChainTransactionPriority);

  @override
  Future<void> setHardwareWalletService(WalletBase wallet, HardwareWalletService service) async {
    if (service is EVMChainLedgerService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmLedgerCredentials).setLedgerConnection(
          service.ledgerConnection, (await wallet.walletInfo.getDerivationInfo()).derivationPath);
    } else if (service is EVMChainBitboxService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmBitboxCredentials)
          .setBitbox(service.manager, (await wallet.walletInfo.getDerivationInfo()).derivationPath);
    }
    return Future.value();
  }

  @override
  HardwareWalletService getLedgerHardwareWalletService(ledger.LedgerConnection connection) =>
      EVMChainLedgerService(connection);

  @override
  HardwareWalletService getBitboxHardwareWalletService(bitbox.BitboxManager manager) =>
      EVMChainBitboxService(manager, chainId: 8453);

  @override
  List<String> getDefaultTokenContractAddresses() =>
      DefaultBaseErc20Tokens().initialBaseErc20Tokens.map((e) => e.contractAddress).toList();

  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final baseWallet = wallet as BaseWallet;
    return baseWallet.erc20Currencies.any(
      (element) => element.contractAddress.toLowerCase() == contractAddress.toLowerCase(),
    );
  }

  @override
  String? getBaseNativeEstimatedFee(WalletBase wallet) =>
      (wallet as EVMChainWallet).nativeTxEstimatedFee;

  @override
  String? getBaseERC20EstimatedFee(WalletBase wallet) =>
      (wallet as EVMChainWallet).erc20TxEstimatedFee;
}
