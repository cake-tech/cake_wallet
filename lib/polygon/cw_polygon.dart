part of 'polygon.dart';

class CWPolygon extends Polygon {
  @override
  List<String> getPolygonWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createPolygonWalletService(Box<WalletInfo> walletInfoSource) =>
      PolygonWalletService(walletInfoSource, client: PolygonClient());

  @override
  WalletCredentials createPolygonNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) =>
      EVMChainNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createPolygonRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
  }) =>
      EVMChainRestoreWalletFromSeedCredentials(name: name, password: password, mnemonic: mnemonic);

  @override
  WalletCredentials createPolygonRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      EVMChainRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  String getAddress(WalletBase wallet) => (wallet as PolygonWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) {
    final privateKeyHolder = (wallet as PolygonWallet).evmChainPrivateKey;
    String stringKey = bytesToHex(privateKeyHolder.privateKey);
    return stringKey;
  }

  @override
  String getPublicKey(WalletBase wallet) {
    final privateKeyInUnitInt = (wallet as PolygonWallet).evmChainPrivateKey;
    final publicKey = privateKeyInUnitInt.address.hex;
    return publicKey;
  }

  @override
  TransactionPriority getDefaultTransactionPriority() => EVMChainTransactionPriority.medium;

  @override
  TransactionPriority getPolygonTransactionPrioritySlow() => EVMChainTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() => EVMChainTransactionPriority.all;

  @override
  TransactionPriority deserializePolygonTransactionPriority(int raw) =>
      EVMChainTransactionPriority.deserialize(raw: raw);

  Object createPolygonTransactionCredentials(
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

  Object createPolygonTransactionCredentialsRaw(
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
  int formatterPolygonParseAmount(String amount) => EVMChainFormatter.parseEVMChainAmount(amount);

  @override
  double formatterPolygonAmountToDouble(
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
    final polygonWallet = wallet as PolygonWallet;
    return polygonWallet.erc20Currencies;
  }

  @override
  Future<void> addErc20Token(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as PolygonWallet).addErc20Token(token as Erc20Token);

  @override
  Future<void> deleteErc20Token(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as PolygonWallet).deleteErc20Token(token as Erc20Token);

  @override
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress) async {
    final polygonWallet = wallet as PolygonWallet;
    return await polygonWallet.getErc20Token(contractAddress);
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as EVMChainTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.maticpoly.title) {
      return CryptoCurrency.maticpoly;
    }

    wallet as PolygonWallet;
    return wallet.erc20Currencies.firstWhere(
        (element) => transaction.tokenSymbol.toLowerCase() == element.symbol.toLowerCase());
  }

  @override
  void updatePolygonScanUsageState(WalletBase wallet, bool isEnabled) {
    (wallet as PolygonWallet).updateScanProviderUsageState(isEnabled);
  }

  @override
  Web3Client? getWeb3Client(WalletBase wallet) {
    return (wallet as PolygonWallet).getWeb3Client();
  }

  String getTokenAddress(CryptoCurrency asset) => (asset as Erc20Token).contractAddress;
}
