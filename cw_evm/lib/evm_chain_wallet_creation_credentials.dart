import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';

class EVMChainNewWalletCredentials extends WalletCredentials {
  EVMChainNewWalletCredentials({required String name, WalletInfo? walletInfo, String? password})
      : super(name: name, walletInfo: walletInfo, password: password);
}

class EVMChainRestoreWalletFromSeedCredentials extends WalletCredentials {
  EVMChainRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);

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
