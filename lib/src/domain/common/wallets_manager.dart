import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';

abstract class WalletsManager {
  Future<Wallet> create(String name, String password);

  Future<Wallet> restoreFromSeed(
      String name, String password, String seed, int restoreHeight);

  Future<Wallet> restoreFromKeys(String name, String password,
      int restoreHeight, String address, String viewKey, String spendKey);

  Future<Wallet> openWallet(String name, String password);

  Future<bool> isWalletExit(String name);

  Future remove(WalletDescription wallet);
}