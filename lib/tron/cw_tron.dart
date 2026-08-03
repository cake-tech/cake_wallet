part of 'tron.dart';

class CWTron extends Tron {
  @override
  List<String> getTronWordList(String language) => EVMChainMnemonics.englishWordlist;

  @override
  WalletService createTronWalletService(bool isDirect) =>
      TronWalletService(client: TronClient(), isDirect: isDirect);

  @override
  WalletCredentials createTronNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? mnemonic,
    String? passphrase,
  }) =>
      TronNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createTronRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      TronRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createTronRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      TronRestoreWalletFromPrivateKey(name: name, password: password, privateKey: privateKey);

  @override
  String getAddress(WalletBase wallet) => (wallet as TronWallet).walletAddresses.address;

  Object createTronTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
  }) =>
      TronTransactionCredentials(
        outputs
            .map(
              (out) => OutputInfo(
                fiatAmount: out.fiatAmount,
                cryptoAmount: out.cryptoAmountMoney,
                address: out.address,
                note: out.note,
                sendAll: out.sendAll,
                extractedAddress: out.extractedAddress,
                isParsedAddress: out.isParsedAddress,
              ),
            )
            .toList(),
        currency: currency,
      );

  @override
  List<TronToken> getTronTokenCurrencies(WalletBase wallet) =>
      (wallet as TronWallet).tronTokenCurrencies;

  @override
  Future<void> addTronToken(WalletBase wallet, CryptoCurrency token, String contractAddress) async {
    final tronToken = TronToken(
      name: token.name,
      symbol: token.title,
      contractAddress: contractAddress,
      decimal: token.decimals,
      enabled: token.enabled,
      iconPath: token.iconPath,
      isPotentialScam: token.isPotentialScam,
    );
    await (wallet as TronWallet).addTronToken(tronToken);
  }

  @override
  Future<void> deleteTronToken(WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as TronWallet).deleteTronToken(token as TronToken);

  @override
  Future<TronToken?> getTronToken(WalletBase wallet, String contractAddress) async =>
      (wallet as TronWallet).getTronToken(contractAddress);

  @override
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction) {
    transaction as TronTransactionInfo;
    if (transaction.amount.currency.symbol == CryptoCurrency.trx.title) {
      return CryptoCurrency.trx;
    }

    wallet as TronWallet;
    return wallet.tronTokenCurrencies.firstWhere((element) =>
        transaction.amount.currency.symbol.toLowerCase() == element.symbol.toLowerCase());
  }

  @override
  String getTokenAddress(CryptoCurrency asset) => (asset as TronToken).contractAddress;

  @override
  String getTronBase58Address(String hexAddress, WalletBase wallet) =>
      (wallet as TronWallet).getTronBase58AddressFromHex(hexAddress);

  @override
  Money? getTronNativeEstimatedFee(WalletBase wallet) =>
      (wallet as TronWallet).nativeTxEstimatedFee;

  @override
  Money? getTronTRC20EstimatedFee(WalletBase wallet) => (wallet as TronWallet).trc20EstimatedFee;

  @override
  void updateTronGridUsageState(WalletBase wallet, bool isEnabled) {
    (wallet as TronWallet).updateScanProviderUsageState(isEnabled);
  }

  @override
  List<TronToken> getDefaultTronTokens() => DefaultTronTokens().initialTronTokens;

  @override
  List<String> getDefaultTokenContractAddresses() {
    return DefaultTronTokens().initialTronTokens.map((e) => e.contractAddress).toList();
  }

  @override
  List<String> getDefaultTokenSymbols() {
    return DefaultTronTokens().initialTronTokens.map((e) => e.symbol.toUpperCase()).toList();
  }

  @override
  bool isTokenAlreadyAdded(WalletBase wallet, String contractAddress) {
    final tronWallet = wallet as TronWallet;
    return tronWallet.tronTokenCurrencies
        .any((element) => element.contractAddress == contractAddress);
  }

  @override
  TransactionInfo getTransactionInfo({
    required String id,
    required Money amount,
    Money? fee,
    required TransactionDirection direction,
    required DateTime blockTime,
    String? to,
    String? from,
    required bool isPending,
  }) =>
      TronTransactionInfo(
          id: id,
          amount: amount,
          fee: fee,
          direction: direction,
          blockTime: blockTime,
          to: to,
          from: from,
          isPending: isPending);
}
