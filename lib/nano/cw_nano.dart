part of 'nano.dart';

class CWNano extends Nano {
  @override
  List<String> getNanoWordList(String language) {
    return NanoMnemomics.WORDLIST;
  }

  @override
  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource) {
    return NanoWalletService(walletInfoSource);
  }

  NanoWalletDetails getNanoWalletDetails(Object wallet) {
    throw UnimplementedError();
  }

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex) {
    throw UnimplementedError();
  }

  @override
  Map<String, String> getKeys(Object wallet) {
    final nanoWallet = wallet as NanoWallet;
    final keys = nanoWallet.keys;
    return <String, String>{
      "seedKey": keys.seedKey,
    };
  }

  @override
  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String? password,
  }) =>
      NanoNewWalletCredentials(
        name: name,
        password: password,
      );

  @override
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    DerivationType? derivationType,
  }) =>
      NanoRestoreWalletFromSeedCredentials(
        name: name,
        password: password,
        mnemonic: mnemonic,
        derivationType: derivationType,
      );

  @override
  TransactionHistoryBase getTransactionHistory(Object wallet) {
    throw UnimplementedError();
  }

  @override
  void onStartup() {}

  @override
  Object createNanoTransactionCredentials(List<Output> outputs) {
    return NanoTransactionCredentials(
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
              ))
          .toList(),
    );
  }
}
