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
    this.chainId,
  });

  final String? mnemonic;
  final int? chainId;
}

class EVMChainRestoreWalletFromSeedCredentials extends WalletCredentials {
  EVMChainRestoreWalletFromSeedCredentials({
    required super.name,
    required super.password,
    required this.mnemonic,
    super.walletInfo,
    super.passphrase,
    this.chainId,
  });

  final String mnemonic;
  final int? chainId;
}

class EVMChainRestoreWalletFromPrivateKey extends WalletCredentials {
  EVMChainRestoreWalletFromPrivateKey({
    required String name,
    required String password,
    required this.privateKey,
    WalletInfo? walletInfo,
    this.chainId,
  }) : super(name: name, password: password, walletInfo: walletInfo);

  final String privateKey;
  final int? chainId;
}

class EVMChainRestoreWalletFromHardware extends WalletCredentials {
  EVMChainRestoreWalletFromHardware({
    required String name,
    required this.hwAccountData,
    WalletInfo? walletInfo,
    this.chainId,
  }) : super(name: name, walletInfo: walletInfo);

  final HardwareAccountData hwAccountData;
  final int? chainId;
}
