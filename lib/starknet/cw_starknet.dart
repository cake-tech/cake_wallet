part of 'starknet.dart';

class CWStarknet extends Starknet {
  @override
  List<String> getStarknetWordList(String language) =>
      StarknetMnemonics.englishWordlist;

  WalletService createStarknetWalletService(bool isDirect) =>
      StarknetWalletService(isDirect);

  @override
  WalletCredentials createStarknetNewWalletCredentials({
    required String name,
    String? mnemonic,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
  }) =>
      StarknetNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createStarknetRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      StarknetRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        passphrase: passphrase,
      );

  @override
  WalletCredentials createStarknetRestoreWalletFromPrivateKey({
    required String name,
    required String privateKey,
    required String password,
  }) =>
      StarknetRestoreWalletFromPrivateKey(
          name: name, password: password, privateKey: privateKey);

  @override
  WalletCredentials createStarknetRestoreWalletFromPublicKey({
    required String name,
    required String publicKey,
    required String password,
    String? accountClassHashHex,
  }) =>
      StarknetRestoreWalletFromPrivateKey.publicKey(
        name: name,
        password: password,
        publicKey: publicKey,
        accountClassHashHex: accountClassHashHex,
      );

  @override
  String getAddress(WalletBase wallet) =>
      (wallet as StarknetWallet).walletAddresses.address;

  @override
  String getPrivateKey(WalletBase wallet) =>
      (wallet as StarknetWallet).privateKey;

  @override
  String getPublicKey(WalletBase wallet) =>
      (wallet as StarknetWallet).publicKey;

  Object createStarknetTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
  }) =>
      StarknetTransactionCredentials(
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
        currency: currency,
      );

  Object createStarknetTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
  }) =>
      StarknetTransactionCredentials(outputs, currency: currency);

  @override
  List<StarknetToken> getStarknetTokenCurrencies(WalletBase wallet) =>
      (wallet as StarknetWallet).starknetTokenCurrencies;

  @override
  Future<void> addStarknetToken(
    WalletBase wallet,
    CryptoCurrency token,
    String contractAddress,
  ) async {
    final starknetToken = StarknetToken(
      name: token.name,
      symbol: token.title,
      contractAddress: contractAddress.toLowerCase(),
      decimal: token.decimals,
      enabled: token.enabled,
      iconPath: token.iconPath,
      isPotentialScam: token.isPotentialScam,
    );

    await (wallet as StarknetWallet).addStarknetToken(starknetToken);
  }

  @override
  Future<void> deleteStarknetToken(
          WalletBase wallet, CryptoCurrency token) async =>
      await (wallet as StarknetWallet)
          .deleteStarknetToken(token as StarknetToken);

  @override
  Future<CryptoCurrency?> getStarknetToken(
          WalletBase wallet, String contractAddress) =>
      (wallet as StarknetWallet).getStarknetToken(contractAddress);

  @override
  double getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as StarknetTransactionInfo).rawAmountAsDouble();
  }

  @override
  CryptoCurrency assetOfTransaction(
      WalletBase wallet, TransactionInfo transaction) {
    final tx = transaction as StarknetTransactionInfo;
    if (tx.tokenAddress.toLowerCase() ==
        StarknetTokenAddresses.strk.toLowerCase()) {
      return CryptoCurrency.strk;
    }

    final starknetWallet = wallet as StarknetWallet;
    return starknetWallet.starknetTokenCurrencies.firstWhere(
      (token) =>
          token.contractAddress.toLowerCase() == tx.tokenAddress.toLowerCase(),
      orElse: () => StarknetToken(
        name: tx.tokenSymbol,
        symbol: tx.tokenSymbol,
        contractAddress: tx.tokenAddress,
        decimal: tx.tokenDecimals,
      ),
    );
  }

  @override
  double? getEstimateFees(WalletBase wallet, {CryptoCurrency? currency}) =>
      (wallet as StarknetWallet).estimatedFeeFor(currency ?? wallet.currency);

  @override
  String getTokenAddress(CryptoCurrency asset) {
    if (asset.titleAndTagEqual(CryptoCurrency.strk)) {
      return StarknetTokenAddresses.strk;
    }

    if (asset is StarknetToken) {
      return asset.contractAddress;
    }

    if (asset.title.toUpperCase() == 'ETH') {
      return StarknetTokenAddresses.eth;
    }

    throw Exception('Unknown Starknet asset address for ${asset.title}');
  }

  @override
  Future<List<String>> signTypedData(
    WalletBase wallet,
    String typedDataJson, {
    String? address,
  }) =>
      (wallet as StarknetWallet).signTypedData(typedDataJson, address: address);

  @override
  Future<String> executeWalletConnectCalls(
    WalletBase wallet,
    List<StarknetExecutionCall> calls,
  ) =>
      (wallet as StarknetWallet).executeCalls(calls);

  @override
  Future<bool> commitTransactionUR(WalletBase wallet, String ur) =>
      (wallet as StarknetWallet).submitSignedTransactionUR(ur);

  @override
  bool supportsOfflineUrSigning(WalletBase wallet) =>
      (wallet as StarknetWallet).supportsOfflineUrSigning;

  @override
  bool isValidAddress(String address) =>
      StarknetWalletClient.isValidAddress(address);
}
