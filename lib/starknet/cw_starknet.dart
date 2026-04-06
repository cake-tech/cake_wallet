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
  double getTransactionAmountRaw(TransactionInfo transactionInfo) {
    return (transactionInfo as StarknetTransactionInfo)
        .starknetAmount
        .toDouble();
  }

  @override
  CryptoCurrency assetOfTransaction(
      WalletBase wallet, TransactionInfo transaction) {
    return CryptoCurrency.strk;
  }

  @override
  double? getEstimateFees(WalletBase wallet) {
    return (wallet as StarknetWallet).estimatedFee;
  }
}
