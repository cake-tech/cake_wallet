import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class BitcoinNewWalletCredentials extends WalletCredentials {
  BitcoinNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    this.mnemonic,
    String? parentAddress,
  }) : super(
          name: name,
          walletInfo: walletInfo,
          password: password,
          passphrase: passphrase,
          parentAddress: parentAddress,
        );

  final String? mnemonic;
}

class BitcoinRestoreWalletFromSeedCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    required super.derivations,
    WalletInfo? walletInfo,
    String? passphrase,
  }) : super(
          name: name,
          password: password,
          passphrase: passphrase,
          walletInfo: walletInfo,
        );

  final String mnemonic;
}

class BitcoinRestoreWalletFromWIFCredentials extends WalletCredentials {
  BitcoinRestoreWalletFromWIFCredentials({
    required String name,
    required String password,
    required this.wif,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);

  final String wif;
}

class BitcoinRestoreWalletFromHardware extends WalletCredentials {
  BitcoinRestoreWalletFromHardware({
    required String name,
    required this.hwAccountData,
    WalletInfo? walletInfo,
  }) : super(name: name, walletInfo: walletInfo);

  final HardwareAccountData hwAccountData;
}
