import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

abstract class WalletService<N extends WalletCredentials, RFS extends WalletCredentials,
    RFK extends WalletCredentials> {
  WalletType getType();

  Future<WalletBase> create(N credentials);

  Future<WalletBase> restoreFromSeed(RFS credentials);

  Future<WalletBase> restoreFromKeys(RFK credentials);

  Future<WalletBase> openWallet(String name, String password);

  Future<bool> isWalletExit(String name);

  Future<void> remove(String wallet);

  Future<void> rename(String currentName, String password, String newName);
}
