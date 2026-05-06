import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class StarknetNewWalletCredentials extends WalletCredentials {
  StarknetNewWalletCredentials({
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

class StarknetRestoreWalletFromSeedCredentials extends WalletCredentials {
  StarknetRestoreWalletFromSeedCredentials({
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

class StarknetRestoreWalletFromPrivateKey extends WalletCredentials {
  StarknetRestoreWalletFromPrivateKey({
    required String name,
    required String password,
    required this.privateKey,
    WalletInfo? walletInfo,
  })  : publicKey = null,
        accountClassHashHex = null,
        super(name: name, password: password, walletInfo: walletInfo);

  StarknetRestoreWalletFromPrivateKey.publicKey({
    required String name,
    required String password,
    required this.publicKey,
    this.accountClassHashHex,
    WalletInfo? walletInfo,
  })  : privateKey = null,
        super(name: name, password: password, walletInfo: walletInfo);

  final String? privateKey;
  final String? publicKey;
  final String? accountClassHashHex;
}

class StarknetRestoreWalletFromHardware extends WalletCredentials {
  StarknetRestoreWalletFromHardware({
    required String name,
    required this.hwAccountData,
    String? password,
    WalletInfo? walletInfo,
    this.accountClassHashHex,
  }) : super(name: name, walletInfo: walletInfo, password: password);

  final HardwareAccountData hwAccountData;
  final String? accountClassHashHex;
}
