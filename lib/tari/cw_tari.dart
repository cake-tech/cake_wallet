part of 'tari.dart';

class CWTari extends Tari {
  List<String> getTariWordList(String language) {
    return []; // ToDo
  }

  WalletService createTariWalletService(Box<WalletInfo> walletInfoSource) =>
      TariWalletService(walletInfoSource);

  WalletCredentials createTariNewWalletCredentials(
          {required String name,
          WalletInfo? walletInfo,
          String? password,
          String? passphrase}) =>
      TariNewWalletCredentials(
          name: name,
          walletInfo: walletInfo,
          password: password,
          passphrase: passphrase);

  WalletCredentials createTariRestoreWalletFromSeedCredentials(
          {required String name,
          required String mnemonic,
          required String password,
          String? passphrase}) =>
      TariRestoreWalletFromSeedCredentials(
          name: name,
          mnemonic: mnemonic,
          password: password,
          passphrase: passphrase);

  String getAddress(WalletBase wallet) =>
      (wallet as TariWallet).walletAddresses.address;

  List<TransactionPriority> getTransactionPriorities() {
    return []; // ToDo
  }

  double formatterTariAmountToDouble({required int amount}) =>
      cryptoAmountToDouble(amount: amount, divider: 1000000);
}
