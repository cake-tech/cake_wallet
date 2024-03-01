import 'dart:io';
import 'package:cw_decred/api/libdcrwallet.dart';
import 'package:cw_decred/wallet_creation_credentials.dart';
import 'package:cw_decred/wallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

class DecredWalletService extends WalletService<
    DecredNewWalletCredentials,
    DecredRestoreWalletFromSeedCredentials,
    DecredRestoreWalletFromWIFCredentials> {
  DecredWalletService(this.walletInfoSource);

  final Box<WalletInfo> walletInfoSource;

  static void init() async {
    // Use the general path for all dcr wallets as the general log directory.
    // Individual wallet paths may be removed if the wallet is deleted.
    final dcrLogDir = await pathForWalletDir(name: '', type: WalletType.decred);
    initLibdcrwallet(dcrLogDir);
  }

  @override
  WalletType getType() => WalletType.decred;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<DecredWallet> create(DecredNewWalletCredentials credentials) async {
    await createWalletAsync(
      name: credentials.walletInfo!.name,
      dataDir: credentials.walletInfo!.dirPath,
      password: credentials.password!,
    );
    final wallet = DecredWallet(credentials.walletInfo!, credentials.password!);
    await wallet.init();
    return wallet;
  }

  @override
  Future<DecredWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values.firstWhereOrNull(
        (info) => info.id == WalletBase.idFor(name, getType()))!;
    await loadWalletAsync(
      name: walletInfo.name,
      dataDir: walletInfo.dirPath,
    );
    final wallet = DecredWallet(walletInfo, password);
    await wallet.init();
    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType()))
        .delete(recursive: true);
    final walletInfo = walletInfoSource.values.firstWhereOrNull(
        (info) => info.id == WalletBase.idFor(wallet, getType()))!;
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(
      String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values.firstWhereOrNull(
        (info) => info.id == WalletBase.idFor(currentName, getType()))!;
    final currentWallet = DecredWallet(currentWalletInfo, password);

    await currentWallet.renameWalletFiles(newName);

    final newDirPath = await pathForWalletDir(name: newName, type: getType());
    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;
    newWalletInfo.dirPath = newDirPath;

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<DecredWallet> restoreFromSeed(
      DecredRestoreWalletFromSeedCredentials credentials) async {
    throw UnimplementedError();
  }

  @override
  Future<DecredWallet> restoreFromKeys(
          DecredRestoreWalletFromWIFCredentials credentials) async =>
      throw UnimplementedError();
}
