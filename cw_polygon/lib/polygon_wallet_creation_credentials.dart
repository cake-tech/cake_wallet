import 'package:cw_core/wallet_info.dart';
import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';

class PolygonNewWalletCredentials extends EVMChainNewWalletCredentials {
  PolygonNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) : super(name: name, walletInfo: walletInfo);
}

class PolygonRestoreWalletFromSeedCredentials extends EVMChainRestoreWalletFromSeedCredentials {
  PolygonRestoreWalletFromSeedCredentials({
    required super.name,
    required super.password,
    required super.mnemonic,
    super.walletInfo,
  });
}

class PolygonRestoreWalletFromPrivateKey extends EVMChainRestoreWalletFromPrivateKey {
  PolygonRestoreWalletFromPrivateKey({
    required super.name,
    required super.password,
    required super.privateKey,
    super.walletInfo,
  });
}
