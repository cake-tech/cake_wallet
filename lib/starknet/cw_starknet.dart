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

  @override
  TransactionPriority getDefaultTransactionPriority() =>
      StarknetTransactionPriority.medium;

  @override
  TransactionPriority getStarknetTransactionPrioritySlow() =>
      StarknetTransactionPriority.slow;

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      StarknetTransactionPriority.all;

  @override
  TransactionPriority deserializeStarknetTransactionPriority(int raw) =>
      StarknetTransactionPriority.deserialize(raw: raw);

  Object createStarknetTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
    TransactionPriority? priority,
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
        priority: priority,
      );

  Object createStarknetTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
    TransactionPriority? priority,
  }) =>
      StarknetTransactionCredentials(
        outputs,
        currency: currency,
        priority: priority,
      );

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
  Future<Map<String, String>> buildMessageSignUr(
    WalletBase wallet,
    String message, {
    String? address,
  }) =>
      (wallet as StarknetWallet).buildMessageSignUr(message, address: address);

  @override
  Future<String> commitMessageUR(WalletBase wallet, String ur) =>
      (wallet as StarknetWallet).submitSignedMessageUr(ur);

  @override
  Future<Map<String, String>> buildTypedDataSignUr(
    WalletBase wallet,
    String typedDataJson, {
    String? address,
  }) =>
      (wallet as StarknetWallet)
          .buildTypedDataSignUr(typedDataJson, address: address);

  @override
  Future<List<String>> commitTypedDataUR(WalletBase wallet, String ur) =>
      (wallet as StarknetWallet).submitSignedTypedDataUr(ur);

  @override
  Future<String> executeWalletConnectCalls(
    WalletBase wallet,
    List<StarknetExecutionCall> calls,
  ) =>
      (wallet as StarknetWallet).executeCalls(calls);

  @override
  Future<Map<String, String>> buildExecutionUr(
    WalletBase wallet,
    List<StarknetExecutionCall> calls,
  ) =>
      (wallet as StarknetWallet).buildExecuteCallsUr(calls);

  @override
  Future<String> commitTransactionUR(
    WalletBase wallet,
    String ur, {
    String? requestUr,
  }) =>
      (wallet as StarknetWallet)
          .submitSignedTransactionUR(ur, requestUrPayload: requestUr);

  @override
  bool supportsOfflineUrSigning(WalletBase wallet) =>
      (wallet as StarknetWallet).supportsOfflineUrSigning;

  @override
  bool isValidAddress(String address) =>
      StarknetWalletClient.isValidAddress(address);
}
