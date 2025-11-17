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
    required WalletType walletType,
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
    required WalletType walletType,
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
    required WalletType walletType,
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
    required WalletType walletType,
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
  String getAddress(WalletBase wallet) =>
      (wallet as EVMChainWallet).walletAddresses.address;

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
  TransactionPriority getDefaultTransactionPriority() =>
      EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getEVMTransactionPrioritySlow() =>
      EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializeEVMTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  @override
  Object createEVMTransactionCredentials(
    WalletType walletType,
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
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
    );
  }

  @override
  Object createEVMTransactionCredentialsRaw(
    WalletType walletType,
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  }) {
    return EVMChainTransactionCredentials(
      outputs,
      priority: priority as EVMChainTransactionPriority?,
      currency: currency,
      feeRate: feeRate,
    );
  }

  @override
  int formatterEVMParseAmount(String amount) =>
      EVMChainFormatter.parseEVMChainAmount(amount);

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
  Future<void> removeTokenTransactionsInHistory(
      WalletBase wallet, CryptoCurrency token) =>
      (wallet as EVMChainWallet).removeTokenTransactionsInHistory(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(
      WalletBase wallet, String contractAddress) {
    final evmWallet = wallet as EVMChainWallet;
    final chainName = EVMChainUtils.getDefaultTokenSymbol(evmWallet.walletInfo.type).toLowerCase();
    return evmWallet.getErc20Token(contractAddress, chainName);
  }

  @override
  CryptoCurrency assetOfTransaction(
      WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    final evmWallet = wallet as EVMChainWallet;
    final isPolygon = evmWallet.walletInfo.type == WalletType.polygon;
    final nativeCurrencyTitle = isPolygon
        ? CryptoCurrency.maticpoly.title
        : CryptoCurrency.eth.title;
    
    if (transaction.tokenSymbol == nativeCurrencyTitle) {
      return isPolygon ? CryptoCurrency.maticpoly : CryptoCurrency.eth;
    }

    return evmWallet.erc20Currencies.firstWhere(
      (element) => transaction.tokenSymbol == element.symbol,
    );
  }

  @override
  void updateScanProviderUsageState(WalletBase wallet, bool isEnabled) =>
      (wallet as EVMChainWallet).updateScanProviderUsageState(isEnabled);

  @override
  Web3Client? getWeb3Client(WalletBase wallet) =>
      (wallet as EVMChainWallet).getWeb3Client();

  @override
  String getTokenAddress(CryptoCurrency asset) =>
      (asset as Erc20Token).contractAddress;

  @override
  Future<bool> isApprovalRequired(
    WalletBase wallet,
    String tokenContract,
    String spender,
    BigInt requiredAmount,
  ) =>
      (wallet as EVMChainWallet)
          .isApprovalRequired(tokenContract, spender, requiredAmount);

  @override
  Future<PendingTransaction> createTokenApproval(
    WalletBase wallet,
    BigInt amount,
    String spender,
    CryptoCurrency token,
    TransactionPriority priority,
  ) {
    final evmWallet = wallet as EVMChainWallet;
    final feeCurrency = EVMChainUtils.getFeeCurrency(evmWallet.walletInfo.type);
    return evmWallet.createApprovalTransaction(
      amount,
      spender,
      token,
      priority as EVMChainTransactionPriority,
      feeCurrency,
    );
  }

  @override
  Future<PendingTransaction> createRawCallDataTransaction(
    WalletBase wallet,
    String to,
    String dataHex,
    BigInt valueWei,
    TransactionPriority priority,
  ) =>
      (wallet as EVMChainWallet).createCallDataTransaction(
        to,
        dataHex,
        valueWei,
        priority as EVMChainTransactionPriority,
      );

  @override
  Future<void> setHardwareWalletService(
      WalletBase wallet, HardwareWalletService service) async {
    if (service is EVMChainLedgerService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmLedgerCredentials)
          .setLedgerConnection(service.ledgerConnection,
              (await wallet.walletInfo.getDerivationInfo()).derivationPath);
    } else if (service is EVMChainBitboxService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmBitboxCredentials)
          .setBitbox(service.manager,
              (await wallet.walletInfo.getDerivationInfo()).derivationPath);
    } else if (service is EVMChainTrezorService) {
      ((wallet as EVMChainWallet).evmChainPrivateKey as EvmTrezorCredentials)
          .setTrezorConnect(service.connect,
              (await wallet.walletInfo.getDerivationInfo()).derivationPath);
    }
  }

  @override
  HardwareWalletService getLedgerHardwareWalletService(
          ledger.LedgerConnection connection) =>
      EVMChainLedgerService(connection);

  @override
  HardwareWalletService getBitboxHardwareWalletService(
          bitbox.BitboxManager manager) =>
      EVMChainBitboxService(manager);

  @override
  HardwareWalletService getTrezorHardwareWalletService(
          trezor.TrezorConnect connect) =>
      EVMChainTrezorService(connect);

  @override
  List<String> getDefaultTokenContractAddresses(WalletType walletType) {
    return EVMChainDefaultTokens.getDefaultTokenAddresses(walletType);
  }

  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final evmWallet = wallet as EVMChainWallet;
    return evmWallet.erc20Currencies.any((element) =>
        element.contractAddress.toLowerCase() == contractAddress.toLowerCase());
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
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet).savingsBalance;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroAccruedInterest(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet).accruedInterest;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroInterestRate(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet).interestRate;
    }
    return null;
  }

  @override
  Future<BigInt>? getDEuroSavingsApproved(WalletBase wallet) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet).approvedBalance;
    }
    return null;
  }

  @override
  Future<PendingTransaction>? addDEuroSaving(
      WalletBase wallet, BigInt amount, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet)
          .depositSavings(amount, priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? removeDEuroSaving(
      WalletBase wallet, BigInt amount, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet)
          .withdrawSavings(amount, priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? reinvestDEuroInterest(
      WalletBase wallet, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet)
          .reinvestInterest(priority as EVMChainTransactionPriority);
    }
    return null;
  }

  @override
  Future<PendingTransaction>? enableDEuroSaving(
      WalletBase wallet, TransactionPriority priority) {
    if (wallet.type == WalletType.ethereum) {
      return DEuro(wallet as EthereumWallet)
          .enableSavings(priority as EVMChainTransactionPriority);
    }
    return null;
  }
}

