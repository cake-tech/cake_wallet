part of 'tron.dart';

class CWTron extends Tron {
  @override
  List<String> getTronWordList(String language) => EVMChainMnemonics.englishWordlist;

  WalletService createTronWalletService(Box<WalletInfo> walletInfoSource) =>
      TronWalletService(walletInfoSource, client: TronClient());

  @override
  WalletCredentials createTronNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) =>
      TronNewWalletCredentials(name: name, walletInfo: walletInfo);

  @override
  WalletCredentials createTronRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
  }) =>
      TronRestoreWalletFromSeedCredentials(name: name, password: password, mnemonic: mnemonic);

  @override
  WalletCredentials createTronRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      TronRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  String getAddress(WalletBase wallet) => (wallet as TronWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) => (wallet as TronWallet).privateKey;

  @override
  String getPublicKey(WalletBase wallet) => (wallet as TronWallet).tronPublicKey.toHex();

  Object createTronTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
    int? feeRate,
  }) =>
      TronTransactionCredentials(
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
        currency: currency,
        feeRate: feeRate,
      );

  Object createTronTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  }) =>
      TronTransactionCredentials(
        outputs,
        currency: currency,
        feeRate: feeRate,
      );

  @override
  List<TronToken> getTronTokenCurrencies(WalletBase wallet) =>
      (wallet as TronWallet).tronTokenCurrencies;

  @override
  Future<void> addTronToken(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as TronWallet).addTronToken(token as TronToken);

  @override
  Future<void> deleteTronToken(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as TronWallet).deleteTronToken(token as TronToken);

  @override
  Future<TronToken?> getTronToken(WalletBase wallet, String contractAddress) async =>
      (wallet as TronWallet).getTronToken(contractAddress);

  @override
  double getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as TronTransactionInfo).tronAmount.toDouble();
  }

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as TronTransactionInfo;
    if (transaction.tokenSymbol == CryptoCurrency.trx.title) {
      return CryptoCurrency.trx;
    }

    wallet as TronWallet;
    return wallet.tronTokenCurrencies.firstWhere(
        (element) => transaction.tokenSymbol.toLowerCase() == element.symbol.toLowerCase());
  }

  String getTokenAddress(CryptoCurrency asset) => (asset as TronToken).contractAddress;
}
