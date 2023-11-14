import 'package:cw_core/wallet_info.dart';
import 'package:cw_ethereum/ethereum_wallet_creation_credentials.dart';

class PolygonNewWalletCredentials extends EthereumNewWalletCredentials {
  PolygonNewWalletCredentials({required String name, WalletInfo? walletInfo})
      : super(name: name, walletInfo: walletInfo);
}

class PolygonRestoreWalletFromSeedCredentials extends EthereumRestoreWalletFromSeedCredentials {
  PolygonRestoreWalletFromSeedCredentials(
      {required String name,
      required String password,
      required String mnemonic,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo, mnemonic: mnemonic);
}

class PolygonRestoreWalletFromPrivateKey extends EthereumRestoreWalletFromPrivateKey {
  PolygonRestoreWalletFromPrivateKey(
      {required String name,
      required String password,
      required String privateKey,
      WalletInfo? walletInfo})
      : super(name: name, password: password, walletInfo: walletInfo, privateKey: privateKey);
}
