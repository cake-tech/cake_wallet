part of 'evm.dart';

class CWEVM extends EVM {
  @override
  List<String> getEVMWordList(String language) => EVMChainMnemonics.englishWordlist;

  @override
  WalletService createEVMWalletService(WalletType walletType, bool isDirect) {
    return EVMChainWalletService(isDirect);
  }

  @override
  WalletCredentials createEVMNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? mnemonic,
    String? passphrase,
  }) {
    return EVMChainNewWalletCredentials(
      name: name,
      walletInfo: walletInfo,
      password: password,
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
  }

  @override
  WalletCredentials createEVMRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) {
    return EVMChainRestoreWalletFromSeedCredentials(
      name: name,
      password: password,
      mnemonic: mnemonic,
      passphrase: passphrase,
    );
  }

  @override
  WalletCredentials createEVMRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) {
    return EVMChainRestoreWalletFromPrivateKey(
      name: name,
      password: password,
      privateKey: privateKey,
    );
  }

  @override
  WalletCredentials createEVMHardwareWalletCredentials({
    required String name,
    required HardwareAccountData hwAccountData,
    WalletInfo? walletInfo,
  }) {
    return EVMChainRestoreWalletFromHardware(
      name: name,
      hwAccountData: hwAccountData,
      walletInfo: walletInfo,
    );
  }

  @override
  String getAddress(WalletBase wallet) => (wallet as EVMChainWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as EVMChainWallet).evmChainPrivateKey;
    if (privateKeyHolder is EthPrivateKey) {
      return bytesToHex(privateKeyHolder.privateKey);
    }
    return "";
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as EVMChainWallet).evmChainPrivateKey;
    return privateKeyInUnitInt.address.hex;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getEVMTransactionPrioritySlow() => EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() => EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializeEVMTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  @override
  Object createEVMTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
    bool useBlinkProtection = true,
  }) {
    return EVMChainTransactionCredentials(
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
      useBlinkProtection: useBlinkProtection,
    );
  }

  @override
  Object createEVMTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
    bool useBlinkProtection = true,
  }) {
    return EVMChainTransactionCredentials(
      outputs,
      priority: priority as EVMChainTransactionPriority?,
      currency: currency,
      feeRate: feeRate,
      useBlinkProtection: useBlinkProtection,
    );
  }

  @override
  int formatterEVMParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

  @override
  double formatterEVMAmountToDouble({
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
      (wallet as EVMChainWallet).erc20Currencies;

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as EVMChainWallet).addErc20Token(token as Erc20Token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) =>
      (wallet as EVMChainWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<void> removeTokenTransactionsInHistory(WalletBase wallet, CryptoCurrency token) =>
      (wallet as EVMChainWallet).removeTokenTransactionsInHistory(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) {
    final evmWallet = wallet as EVMChainWallet;
    final chainName = EVMChainUtils.getDefaultTokenSymbol(evmWallet.selectedChainId).toLowerCase();
    return evmWallet.getErc20Token(contractAddress, chainName);
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    final evmWallet = wallet as EVMChainWallet;

    final nativeCurrency = evmWallet.currency;
    final nativeCurrencyTitle = nativeCurrency.title;

    if (transaction.tokenSymbol == CryptoCurrency.maticpoly.title ||
        transaction.tokenSymbol == "MATIC") {
      return CryptoCurrency.maticpoly;
    }

    if (transaction.tokenSymbol == nativeCurrencyTitle) {
      return nativeCurrency;
    }

    // Otherwise, it's an ERC20 token
    return evmWallet.erc20Currencies.firstWhere(
      (element) =>
          transaction.contractAddress?.toLowerCase() == element.contractAddress.toLowerCase(),
    );
  }

  @override
  void updateScanProviderUsageState(WalletBase wallet, bool isEnabled) =>
      (wallet as EVMChainWallet).updateScanProviderUsageState(isEnabled);

  @override
  Web3Client? getWeb3Client(WalletBase wallet) => (wallet as EVMChainWallet).getWeb3Client();

  @override
  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;

  @override
  Future<bool> isApprovalRequired(
    WalletBase wallet,
    String tokenContract,
    String spender,
    BigInt requiredAmount,
  ) =>
      (wallet as EVMChainWallet).isApprovalRequired(tokenContract, spender, requiredAmount);

  @override
  Future<PendingTransaction> createTokenApproval(WalletBase wallet, BigInt amount, String spender,
      CryptoCurrency token, TransactionPriority priority,
      {bool useBlinkProtection = true}) {
    final evmWallet = wallet as EVMChainWallet;
    final feeCurrency = EVMChainUtils.getFeeCurrency(evmWallet.selectedChainId);
    return evmWallet.createApprovalTransaction(
      amount,
      spender,
      token,
      priority as EVMChainTransactionPriority,
      feeCurrency,
      useBlinkProtection: useBlinkProtection,
    );
  }

  @override
  Future<PendingTransaction> createRawCallDataTransaction(
    WalletBase wallet,
    String to,
    String dataHex,
    BigInt valueWei,
    TransactionPriority priority, {
    bool useBlinkProtection = true,
  }) =>
      (wallet as EVMChainWallet).createCallDataTransaction(
        to,
        dataHex,
        valueWei,
        priority as EVMChainTransactionPriority,
        useBlinkProtection: useBlinkProtection,
      );

  @override
  Future<void> setHardwareWalletService(
    WalletBase wallet,
    HardwareWalletService service,
  ) async {
    final evmWallet = wallet as EVMChainWallet;
    final privateKey = evmWallet.evmChainPrivateKey;
    final derivationPath = (await wallet.walletInfo.getDerivationInfo()).derivationPath;

    if (service is EVMChainLedgerService) {
      (privateKey as EvmLedgerCredentials)
          .setLedgerConnection(service.ledgerConnection, derivationPath);
    } else if (service is EVMChainBitboxService) {
      (privateKey as EvmBitboxCredentials).setBitbox(service.manager, derivationPath);
    } else if (service is EVMChainTrezorService) {
      (privateKey as EvmTrezorCredentials).setTrezorConnect(service.connect, derivationPath);
    }
  }

  @override
  HardwareWalletService getLedgerHardwareWalletService(ledger.LedgerConnection connection) =>
      EVMChainLedgerService(connection);

  @override
  HardwareWalletService getBitboxHardwareWalletService(bitbox.BitboxManager manager) =>
      EVMChainBitboxService(manager);

  @override
  HardwareWalletService getTrezorHardwareWalletService(trezor.TrezorConnect connect) =>
      EVMChainTrezorService(connect);

  @override
  List<String> getDefaultTokenContractAddresses(WalletBase wallet) {
    final chainId = getSelectedChainId(wallet);
    if (chainId == null) return [];
    return EVMChainDefaultTokens.getDefaultTokenAddresses(chainId);
  }

  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final evmWallet = wallet as EVMChainWallet;
    return evmWallet.erc20Currencies
        .any((element) => element.contractAddress.toLowerCase() == contractAddress.toLowerCase());
  }

  @override
  String? getEVMNativeEstimatedFee(WalletBase wallet) =>
      (wallet as EVMChainWallet).nativeTxEstimatedFee;

  @override
  String? getEVMERC20EstimatedFee(WalletBase wallet) =>
      (wallet as EVMChainWallet).erc20TxEstimatedFee;

  // Chain-specific integrations (only for Ethereum)
  @override
  Future<BigInt>? getDEuroSavingsBalance(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).savingsBalance;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroAccruedInterest(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).accruedInterest;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroInterestRate(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).interestRate;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroSavingsApproved(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).approvedBalance;
    }
    return null;
  }

  @override
  Future<PendingTransaction>? addDEuroSaving(
      WalletBase wallet, BigInt amount, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).depositSavings(amount, priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? removeDEuroSaving(
      WalletBase wallet, BigInt amount, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).withdrawSavings(amount, priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? reinvestDEuroInterest(
      WalletBase wallet, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).reinvestInterest(priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? enableDEuroSaving(WalletBase wallet, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum && wallet is EVMChainWallet) {
      return DEuro(wallet).enableSavings(priority as EVMChainTransactionPriority);
    }
    return null;
  }

  // Registry helper methods
  static final EvmChainRegistry _registry = EvmChainRegistry();

  @override
  int getChainIdByWalletType(WalletType walletType) {
    final config = _registry.getChainConfigByWalletType(walletType);
    return config?.chainId ?? 1; // Default to Ethereum
  }

  @override
  String getChainNameByWalletType(WalletType walletType) {
    final config = _registry.getChainConfigByWalletType(walletType);
    return config?.shortCode ?? 'eth';
  }

  @override
  String getTokenNameByWalletType(WalletType walletType) {
    final config = _registry.getChainConfigByWalletType(walletType);
    return config?.nativeCurrency.title ?? 'ETH';
  }

  @override
  String getCaip2ByChainId(int chainId) {
    final config = _registry.getChainConfig(chainId);
    return config?.caip2 ?? 'eip155:1';
  }

  @override
  String getChainNameByChainId(int chainId) {
    final config = _registry.getChainConfig(chainId);
    return config?.shortCode ?? 'eth';
  }

  @override
  String getTokenNameByChainId(int chainId) {
    final config = _registry.getChainConfig(chainId);
    return config?.nativeCurrency.title ?? 'ETH';
  }

  @override
  int? getChainIdByTag(String tag) {
    final config = _registry.getChainConfigByTag(tag);
    return config?.chainId;
  }

  @override
  int? getChainIdByTitle(String title) {
    // Try as tag first (uppercase)
    final tagResult = getChainIdByTag(title.toUpperCase());
    if (tagResult != null) return tagResult;

    // Try as lowercase title
    return getChainIdByTag(title.toLowerCase());
  }

  @override
  WalletType? getWalletTypeByChainId(int chainId) {
    return _registry.getWalletTypeByChainId(chainId);
  }

  @override
  List<ChainInfo> getAllChains() {
    final allChains = _registry.getAllChains();
    return allChains
        .map((config) => ChainInfo(
              chainId: config.chainId,
              name: config.name,
              shortCode: config.shortCode,
            ))
        .toList();
  }

  @override
  ChainInfo? getCurrentChain(WalletBase wallet) {
    if (wallet is EVMChainWallet) {
      final config = wallet.selectedChainConfig;
      if (config == null) return null;
      return ChainInfo(
        chainId: config.chainId,
        name: config.name,
        shortCode: config.shortCode,
      );
    }
    return null;
  }

  @override
  int? getSelectedChainId(WalletBase wallet) {
    if (wallet is EVMChainWallet) {
      return wallet.selectedChainId;
    }
    return null;
  }

  @override
  Future<void> selectChain(WalletBase wallet, int chainId, {required Node node}) async {
    if (wallet is EVMChainWallet) {
      await wallet.selectChain(chainId, node: node);
    }
  }

  @override
  String? getExplorerUrlForChainId(int chainId, String txId) {
    final config = _registry.getChainConfig(chainId);
    if (config != null && config.explorerUrls.isNotEmpty) {
      return '${config.explorerUrls.first}/tx/$txId';
    }
    return null;
  }
}
