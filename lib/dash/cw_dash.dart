part of 'dash.dart';

class CWDash extends Dash {
  @override
  WalletService createDashWalletService(
      Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return DashWalletService(unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createDashNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  }) =>
      DashNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        passphrase: passphrase,
        mnemonic: mnemonic,
      );

  @override
  WalletCredentials createDashRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  }) =>
      DashRestoreWalletFromSeedCredentials(
          name: name, mnemonic: mnemonic, password: password, passphrase: passphrase);

  @override
  TransactionPriority deserializeDashTransactionPriority(int raw) =>
      DashTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() => DashTransactionPriority.medium;
  @override
  List<TransactionPriority> getTransactionPriorities() => DashTransactionPriority.all;
  @override
  TransactionPriority getDashTransactionPrioritySlow() => DashTransactionPriority.slow;
}
