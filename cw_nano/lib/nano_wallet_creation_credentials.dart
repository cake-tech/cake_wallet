import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class NanoNewWalletCredentials extends WalletCredentials {
  NanoNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    DerivationType? derivationType,
    this.mnemonic,
    String? passphrase,
  }) : super(
          name: name,
          password: password,
          walletInfo: walletInfo,
          passphrase: passphrase,
        );

  final String? mnemonic;
}

class NanoRestoreWalletFromSeedCredentials extends WalletCredentials {
  NanoRestoreWalletFromSeedCredentials({
    required String name,
    required this.mnemonic,
    String? password,
    required DerivationType derivationType,
    String? passphrase,
  }) : super(
          name: name,
          password: password,
          derivationInfo: DerivationInfo(derivationType: derivationType),
          passphrase: passphrase,
        );

  final String mnemonic;
}

class NanoWalletLoadingException implements Exception {
  @override
  String toString() => 'Failure to load the wallet.';
}

class NanoRestoreWalletFromKeysCredentials extends WalletCredentials {
  NanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required DerivationType derivationType,
    required this.seedKey,
  }) : super(
          name: name,
          password: password,
          derivationInfo: DerivationInfo(derivationType: derivationType),
        );

  final String seedKey;
}
