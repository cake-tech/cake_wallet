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
    required CryptoCurrency currency,
    TransactionPriority? priority,
    int? feeRate,
    bool useBlinkProtection = true,
  }) =>
      EVMChainTransactionCredentials(
        outputs
            .map((out) => OutputInfo(
                  fiatAmount: out.fiatAmount,
                  cryptoAmount: out.cryptoAmountMoney,
                  address: out.address,
                  note: out.note,
                  sendAll: out.sendAll,
                  extractedAddress: out.extractedAddress,
                  isParsedAddress: out.isParsedAddress,
                  memo: out.memo,
                ))
            .toList(),
        priority: priority as EVMChainTransactionPriority?,
        currency: currency,
        feeRate: feeRate,
        useBlinkProtection: useBlinkProtection,
      );

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
  TransactionInfo getTransactionInfo({
    required String id,
    required int height,
    required Money amount,
    required Money fee,
    required String tokenSymbol,
    int exponent = 18,
    required TransactionDirection direction,
    required bool isPending,
    required DateTime date,
    required int confirmations,
    String? to,
    String? from,
    String? evmSignatureName,
    String? contractAddress,
    required int chainId,
  }) =>
      EVMChainTransactionInfo(
          id: id,
          height: height,
          amount: amount,
          fee: fee,
          tokenSymbol: tokenSymbol,
          exponent: exponent,
          direction: direction,
          isPending: isPending,
          date: date,
          confirmations: confirmations,
          to: to,
          from: from,
          evmSignatureName: evmSignatureName,
          contractAddress: contractAddress,
          chainId: chainId);

  @override
  int formatterEVMParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

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
    final currentChainId = evmWallet.selectedChainId;

    // If transaction is from a different chain, we will return native currency as fallback
    // This can happen during chain switching when old transactions are still visible
    if (transaction.chainId != currentChainId) {
      return nativeCurrency;
    }

    if (transaction.tokenSymbol == CryptoCurrency.maticpoly.title ||
        transaction.tokenSymbol == "MATIC") {
      return CryptoCurrency.maticpoly;
    }

    if (transaction.tokenSymbol == nativeCurrencyTitle) {
      return nativeCurrency;
    }

    // Otherwise, it's an ERC20 token
    // Also using firstWhereOrNull to handle cases where token isn't found (e.g., during chain switch)
    final erc20Token = evmWallet.erc20Currencies.firstWhereOrNull(
      (element) =>
          transaction.contractAddress?.toLowerCase() == element.contractAddress.toLowerCase(),
    );

    return erc20Token ?? nativeCurrency;
  }

  @override
  void updateScanProviderUsageState(WalletBase wallet, bool isEnabled) =>
      (wallet as EVMChainWallet).updateScanProviderUsageState(isEnabled);

  @override
  Web3Client? getWeb3Client(WalletBase wallet) => (wallet as EVMChainWallet).getWeb3Client();

  @override
  Future<bool?> getTransactionReceipt(WalletBase wallet, String txHash) async {
    final client = getWeb3Client(wallet);
    if (client == null) return null;

    try {
      final receipt = await client.getTransactionReceipt(txHash);

      if (receipt == null) return null;

      return receipt.status;
    } catch (_) {
      return null;
    }
  }

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
  Future<BigInt?> getAllowance(WalletBase wallet, String tokenContract, String spender) =>
      (wallet as EVMChainWallet).getAllowance(tokenContract, spender);

  @override
  Future<PendingTransaction> createTokenApproval(
    WalletBase wallet,
    Money amount,
    String spender,
    TransactionPriority? priority, {
    bool useBlinkProtection = true,
  }) {
    final evmWallet = wallet as EVMChainWallet;
    return evmWallet.createApprovalTransaction(
      amount,
      spender,
      priority as EVMChainTransactionPriority?,
      useBlinkProtection: useBlinkProtection,
    );
  }

  @override
  Future<PendingTransaction> createRawCallDataTransaction(
    WalletBase wallet,
    String to,
    String dataHex,
    Money valueWei,
    TransactionPriority? priority, {
    bool useBlinkProtection = true,
    String? sourceTokenAddress,
    BigInt? sourceTokenAmount,
  }) =>
      (wallet as EVMChainWallet).createCallDataTransaction(
        to,
        dataHex,
        valueWei,
        priority as EVMChainTransactionPriority?,
        sourceTokenAddress,
        sourceTokenAmount,
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
  List<Erc20Token> getDefaultTokensByChainId(int chainId) =>
      EVMChainDefaultTokens.getDefaultTokensByChainId(chainId);

  @override
  List<String> getDefaultTokenContractAddresses(WalletBase wallet) {
    final chainId = getSelectedChainId(wallet);
    if (chainId == null) return [];
    return EVMChainDefaultTokens.getDefaultTokenAddresses(chainId);
  }

  @override
  List<String> getDefaultTokenSymbols(WalletBase wallet) {
    final chainId = getSelectedChainId(wallet);
    if (chainId == null) return [];
    return EVMChainDefaultTokens.getDefaultTokenSymbols(chainId);
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
  Future<Money>? getDEuroSavingsBalance(WalletBase wallet) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).savingsBalance;
    }
    return null;
  }

  @override
  Future<Money>? getDEuroSavingsV1Balance(WalletBase wallet) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).savingsBalanceV1;
    }
    return null;
  }

  @override
  Future<Money>? getDEuroAccruedInterest(WalletBase wallet) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).accruedInterest;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroInterestRate(WalletBase wallet) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).interestRate;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroSavingsApproved(WalletBase wallet) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).approvedBalance;
    }
    return null;
  }

  @override
  Future<PendingTransaction>? addDEuroSaving(
      WalletBase wallet, BigInt amount, TransactionPriority priority) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).depositSavings(amount, priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? removeDEuroSaving(
      WalletBase wallet, BigInt amount, TransactionPriority priority) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).withdrawSavings(amount, priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? withdrawDEuroSavingV1(
      WalletBase wallet, TransactionPriority priority) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).withdrawSavingsV1(priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? reinvestDEuroInterest(
      WalletBase wallet, TransactionPriority priority) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
      return DEuro(wallet).reinvestInterest(priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? enableDEuroSaving(WalletBase wallet, TransactionPriority priority) {
    if (wallet.chainId == 1 && wallet is EVMChainWallet) {
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
              currency: config.nativeCurrency,
            ))
        .toList();
  }

  @override
  ChainInfo? getChainInfoByChainId(int chainId) {
    final config = _registry.getChainConfig(chainId);
    if (config == null) return null;

    return ChainInfo(
      chainId: config.chainId,
      name: config.name,
      shortCode: config.shortCode,
      currency: config.nativeCurrency,
    );
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
        currency: config.nativeCurrency,
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
  String? getExplorerUrlForChainId(int chainId, {bool showProtocol = true}) {
    final config = _registry.getChainConfig(chainId);

    if (config != null && config.explorerUrls.isNotEmpty) {
      final url = config.explorerUrls.first;
      return showProtocol
          ? url
          : url.replaceAll('https://', '').replaceAll('http://', '').split('/')[0];
    }
    return null;
  }

  @override
  bool hasPriorityFee(int chainId) => EVMChainUtils.hasPriorityFee(chainId);

  @override
  bool isUSDT0Token(WalletBase wallet, CryptoCurrency token) {
    if (token is! Erc20Token) return false;

    final chainId = getSelectedChainId(wallet);
    if (chainId == null) return false;

    return USDT0Config.isUSDT0Token(token, chainId);
  }

  @override
  List<ChainInfo> getUSDT0DestinationChains(WalletBase wallet) {
    final currentChainId = getSelectedChainId(wallet);
    if (currentChainId == null) return [];

    final result = <ChainInfo>[];
    for (final config in _registry.getAllChains()) {
      if (USDT0Config.isChainSupported(config.chainId) && config.chainId != currentChainId) {
        result.add(ChainInfo(
          chainId: config.chainId,
          name: config.name,
          shortCode: config.shortCode,
          currency: config.nativeCurrency,
        ));
      }
    }
    return result;
  }

  @override
  Future<BridgeQuote> quoteUSDT0Transfer({
    required WalletBase wallet,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
  }) async {
    final evmWallet = wallet as EVMChainWallet;
    final client = evmWallet.getWeb3Client();
    if (client == null) {
      throw StateError('Wallet not connected');
    }

    final quote = await USDT0Service.quoteCrossChainTransfer(
      client: client,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      amount: amount,
      recipientAddress: recipientAddress,
    );
    return BridgeQuote(
      nativeFee: quote.nativeFee,
      lzTokenFee: quote.lzTokenFee,
    );
  }

  @override
  Future<PendingTransaction> executeUSDT0Transfer({
    required WalletBase wallet,
    required CryptoCurrency token,
    required int sourceChainId,
    required int destinationChainId,
    required BigInt amount,
    required String recipientAddress,
    required BridgeQuote quote,
    required TransactionPriority priority,
    bool useBlinkProtection = true,
  }) {
    final evmWallet = wallet as EVMChainWallet;
    final tokenErc20 = token as Erc20Token;

    return USDT0Service.executeCrossChainTransfer(
      wallet: evmWallet,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      amount: amount,
      recipientAddress: recipientAddress,
      quote: USDT0Quote(nativeFee: quote.nativeFee, lzTokenFee: quote.lzTokenFee),
      token: tokenErc20,
      priority: priority as EVMChainTransactionPriority,
      useBlinkProtection: useBlinkProtection,
    );
  }

  Future<EvmWalletConnectFeeQuote?> getWCBufferedFeeQuote(
    WalletBase wallet,
    TransactionPriority priority,
  ) async {
    if (wallet is! EVMChainWallet) return null;

    final data = await wallet.getWCBufferedFeeQuote(priority);
    if (data == null) return null;

    return EvmWalletConnectFeeQuote(
      maxFeePerGasWei: data.maxFeePerGasWei,
      maxPriorityFeePerGasWei: data.maxPriorityFeePerGasWei,
      latestBaseFeeWei: data.latestBaseFeeWei,
    );
  }

  Future<double> _fetchFiatApiPriceForToken(Erc20Token token) async {
    try {
      final settingsStore = getIt.get<SettingsStore>();
      final torOnly = settingsStore.fiatApiMode == FiatApiMode.torOnly;

      return await FiatConversionService.fetchPrice(
        crypto: token,
        fiat: FiatCurrency.usd,
        torOnly: torOnly,
      );
    } catch (_) {
      return 0.0;
    }
  }

  static const _minTokenUsdValue = 0.1;
  @override
  Future<void> discoverAndAddWalletTokens(WalletBase wallet) async {
    if (wallet is! EVMChainWallet) return;

    try {
      final result = await wallet.discoverTokensFromMoralis();

      if (result.newTokens.isEmpty) return;

      final List<Future<void>> tokenChecks = [];

      final whitelistedContracts =
          wallet.getDefaultTokenContractAddresses.map((a) => a.toLowerCase()).toSet();

      for (final item in result.newTokens) {
        tokenChecks.add((() async {
          final token = item.token;

          final isPropertiesSuspicious = wallet.isTokenPropertiesSuspicious(token);
          final isWhitelisted = whitelistedContracts.contains(token.contractAddress.toLowerCase());

          final moralisPrice = item.moralisUsdPrice;
          final moralisValue = item.moralisUsdValue ?? 0.0;
          final hasMoralisPrice = moralisPrice != null && moralisPrice > 0;

          final fiatApiPrice = await _fetchFiatApiPriceForToken(token);
          final hasFiatApiPrice = fiatApiPrice > 0;

          final isImpersonator =
              hasFiatApiPrice && !hasMoralisPrice && !isWhitelisted && !item.verifiedContract;

          final isSpam = isPropertiesSuspicious ||
              token.isPotentialScam ||
              isImpersonator ||
              (!hasMoralisPrice && !hasFiatApiPrice);

          token.isPotentialScam = isSpam;
          token.enabled =
              hasMoralisPrice && hasFiatApiPrice && (moralisValue >= _minTokenUsdValue) && !isSpam;

          await wallet.addErc20Token(token);
        })());
      }

      await Future.wait(tokenChecks);
    } catch (_) {}
  }
}
