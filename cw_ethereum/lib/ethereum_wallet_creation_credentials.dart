import 'package:cw_evm/evm_chain_wallet_creation_credentials.dart';

class EthereumNewWalletCredentials extends EVMChainNewWalletCredentials {
  EthereumNewWalletCredentials({required super.name, super.walletInfo});
}

class EthereumRestoreWalletFromSeedCredentials extends EVMChainRestoreWalletFromSeedCredentials {
  EthereumRestoreWalletFromSeedCredentials({
    required super.name,
    required super.password,
    required super.mnemonic,
    super.walletInfo,
  });
}

class EthereumRestoreWalletFromPrivateKey extends EVMChainRestoreWalletFromPrivateKey {
  EthereumRestoreWalletFromPrivateKey({
    required super.name,
    required super.password,
    required super.privateKey,
    super.walletInfo,
  });
}
