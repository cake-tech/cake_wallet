import 'package:cake_wallet/core/wallet_credentials.dart';

abstract class WalletListService<N extends WalletCredentials,
    RFS extends WalletCredentials, RFK extends WalletCredentials> {
  Future<void> create(N credentials);

  Future<void> restoreFromSeed(RFS credentials);

  Future<void> restoreFromKeys(RFK credentials);

  Future<void> openWallet(String name, String password);

  Future<bool> isWalletExit(String name);

  Future<void> remove(String wallet);
}
