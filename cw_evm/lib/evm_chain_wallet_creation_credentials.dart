import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class EVMChainNewWalletCredentials extends WalletCredentials {
  EVMChainNewWalletCredentials({
    required super.name,
    super.walletInfo,
    super.password,
    this.mnemonic,
    super.passphrase,
  });

  final String? mnemonic;
}

class EVMChainRestoreWalletFromSeedCredentials extends WalletCredentials {
  EVMChainRestoreWalletFromSeedCredentials({
    required super.name,
    required super.password,
    required this.mnemonic,
    super.walletInfo,
    super.passphrase,
  });

  final String mnemonic;
}

class EVMChainRestoreWalletFromPrivateKey extends WalletCredentials {
  EVMChainRestoreWalletFromPrivateKey({
    required String name,
    required String password,
    required this.privateKey,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
}

class EVMChainRestoreWalletFromHardware extends WalletCredentials {
  EVMChainRestoreWalletFromHardware({
    required String name,
    required this.hwAccountData,
    WalletInfo? walletInfo,
  }) : super(name: name, walletInfo: walletInfo);

  final HardwareAccountData hwAccountData;
}
