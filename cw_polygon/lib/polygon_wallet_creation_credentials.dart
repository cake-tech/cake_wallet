import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';

class PolygonNewWalletCredentials extends EVMChainNewWalletCredentials {
  PolygonNewWalletCredentials({required super.name, super.walletInfo});
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
