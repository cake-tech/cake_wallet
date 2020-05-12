import 'dart:io';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cake_wallet/bitcoin/bitcoin_wallet.dart';
import 'package:cake_wallet/src/domain/common/pathForWallet.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/wallets_manager.dart';

class BitcoinWalletManager extends WalletsManager {
  @override
  Future<Wallet> create(String name, String password, String language) async {
    final wallet = await BitcoinWallet.build(
        mnemonic: bip39.generateMnemonic(), password: password, name: name);
    await wallet.save();

    return wallet;
  }

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: WalletType.bitcoin))
          .existsSync();

  @override
  Future<Wallet> openWallet(String name, String password) async {
    return BitcoinWallet.load(
        name: name, password: password);
  }

  @override
  Future remove(WalletDescription wallet) async {
    final path = await pathForWalletDir(name: wallet.name, type: wallet.type);
    final f = File(path);

    if (!f.existsSync()) {
      return;
    }

    f.deleteSync();
  }

  @override
  Future<Wallet> restoreFromKeys(String name, String password, String language,
      int restoreHeight, String address, String viewKey, String spendKey) {
    // TODO: implement restoreFromKeys
    return null;
  }

  @override
  Future<Wallet> restoreFromSeed(
      String name, String password, String seed, int restoreHeight) async {
    final wallet = await BitcoinWallet.build(
        name: name, password: password, mnemonic: seed);
    await wallet.save();

    return wallet;
  }
}
