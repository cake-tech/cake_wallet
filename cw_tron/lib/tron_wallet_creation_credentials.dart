import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';

class TronNewWalletCredentials extends WalletCredentials {
  TronNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    this.mnemonic,
    String? passphrase,
  }) : super(
          name: name,
          walletInfo: walletInfo,
          password: password,
          passphrase: passphrase,
        );

  final String? mnemonic;
}

class TronRestoreWalletFromSeedCredentials extends WalletCredentials {
  TronRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(
          name: name,
          password: password,
          walletInfo: walletInfo,
          passphrase: passphrase,
        );

  final String mnemonic;
}

class TronRestoreWalletFromPrivateKey extends WalletCredentials {
  TronRestoreWalletFromPrivateKey(
      {required String name,
      required String password,
      required this.privateKey,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}

class TronRestoreWalletFromHardware extends WalletCredentials {
  TronRestoreWalletFromHardware({
    required super.name,
    required this.accountData,
    super.walletInfo,
    super.password,
  });

  final HardwareAccountData accountData;
}
