import 'dart:convert';
import 'dart:io';
import 'package:cw_decred/api/libdcrwallet.dart';
import 'package:cw_decred/wallet_creation_credentials.dart';
import 'package:cw_decred/wallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:path/path.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/unspent_coins_info.dart';

class DecredWalletService extends WalletService<
    DecredNewWalletCredentials,
    DecredRestoreWalletFromSeedCredentials,
    DecredRestoreWalletFromPubkeyCredentials,
    DecredRestoreWalletFromHardwareCredentials> {
  DecredWalletService(this.walletInfoSource, this.unspentCoinsInfoSource);

  final Box<WalletInfo> walletInfoSource;
  final Box<UnspentCoinsInfo> unspentCoinsInfoSource;
  final seedRestorePath = "m/44'/42'";
  static final seedRestorePathTestnet = "m/44'/1'";
  static final pubkeyRestorePath = "m/44'/42'/0'";
  static final pubkeyRestorePathTestnet = "m/44'/1'/0'";
  final mainnet = "mainnet";
  final testnet = "testnet";
  static Libwallet? libwallet;

  Future<void> init() async {
    if (libwallet != null) {
      return;
    }
    libwallet = await Libwallet.spawn();
    // Init logging with no directory to force printing to stdout and only
    // print ERROR level logs.
    libwallet!.initLibdcrwallet("", "err");
  }

  void closeLibwallet() {
    if (libwallet == null) {
      return;
    }
    libwallet!.close();
    libwallet = null;
  }

  @override
  WalletType getType() => WalletType.decred;

  @override
  Future<bool> isWalletExit(String name) async =>
      File(await pathForWallet(name: name, type: getType())).existsSync();

  @override
  Future<DecredWallet> create(DecredNewWalletCredentials credentials, {bool? isTestnet}) async {
    await this.init();
    final dirPath = await pathForWalletDir(name: credentials.walletInfo!.name, type: getType());
    final network = isTestnet == true ? testnet : mainnet;
    final config = {
      "name": credentials.walletInfo!.name,
      "datadir": dirPath,
      "pass": credentials.password!,
      "net": network,
      "unsyncedaddrs": true,
    };
    await libwallet!.createWallet(jsonEncode(config));
    final di = DerivationInfo(
        derivationPath: isTestnet == true ? seedRestorePathTestnet : seedRestorePath);
    credentials.walletInfo!.derivationInfo = di;
    credentials.walletInfo!.network = network;
    // ios will move our wallet directory when updating. Since we must
    // recalculate the new path every time we open the wallet, ensure this path
    // is not used. An older wallet will have a directory here which is a
    // condition for moving the wallet when opening, so this must be kept blank
    // going forward.
    credentials.walletInfo!.dirPath = "";
    credentials.walletInfo!.path = "";
    final wallet = DecredWallet(credentials.walletInfo!, credentials.password!,
        this.unspentCoinsInfoSource, libwallet!, closeLibwallet);
    await wallet.init();
    return wallet;
  }

  void copyDirectorySync(Directory source, Directory destination) {
    /// create destination folder if not exist
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    /// get all files from source (recursive: false is important here)
    source.listSync(recursive: false).forEach((entity) {
      final newPath = destination.path + Platform.pathSeparator + basename(entity.path);
      if (entity is File) {
        entity.rename(newPath);
      } else if (entity is Directory) {
        copyDirectorySync(entity, Directory(newPath));
      }
    });
  }

  Future<void> moveWallet(String fromPath, String toPath) async {
    final oldWalletDir = new Directory(fromPath);
    final newWalletDir = new Directory(toPath);
    copyDirectorySync(oldWalletDir, newWalletDir);
    // It would be ideal to delete the old directory here, but ios will error
    // sometimes with "OS Error: No such file or directory, errno = 2" even
    // after checking if it exists.
  }

  @override
  Future<DecredWallet> openWallet(String name, String password) async {
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(name, getType()))!;
    if (walletInfo.network == null || walletInfo.network == "") {
      walletInfo.network = walletInfo.derivationInfo?.derivationPath == seedRestorePathTestnet ||
              walletInfo.derivationInfo?.derivationPath == pubkeyRestorePathTestnet
          ? testnet
          : mainnet;
    }

    await this.init();

    // Cake wallet version 4.27.0 and earlier gave a wallet dir that did not
    // match the name. Move those to the correct place.
    final dirPath = await pathForWalletDir(name: name, type: getType());
    if (walletInfo.path != "") {
      // On ios the stored dir no longer exists. We can only trust the basename.
      // dirPath may already be updated and lost the basename, so look at path.
      final randomBasename = basename(walletInfo.path);
      final oldDir = await pathForWalletDir(name: randomBasename, type: getType());
      if (oldDir != dirPath) {
        await this.moveWallet(oldDir, dirPath);
      }
      // Clear the path so this does not trigger again.
      walletInfo.dirPath = "";
      walletInfo.path = "";
      await walletInfo.save();
    }

    final config = {
      "name": name,
      "datadir": dirPath,
      "net": walletInfo.network,
      "unsyncedaddrs": true,
    };
    await libwallet!.loadWallet(jsonEncode(config));
    final wallet =
        DecredWallet(walletInfo, password, this.unspentCoinsInfoSource, libwallet!, closeLibwallet);
    await wallet.init();
    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    File(await pathForWalletDir(name: wallet, type: getType())).delete(recursive: true);
    final walletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(wallet, getType()))!;
    await walletInfoSource.delete(walletInfo.key);
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = walletInfoSource.values
        .firstWhereOrNull((info) => info.id == WalletBase.idFor(currentName, getType()))!;
    final network = currentWalletInfo.derivationInfo?.derivationPath == seedRestorePathTestnet ||
            currentWalletInfo.derivationInfo?.derivationPath == pubkeyRestorePathTestnet
        ? testnet
        : mainnet;
    if (libwallet == null) {
      libwallet = await Libwallet.spawn();
      libwallet!.initLibdcrwallet("", "err");
    }
    final currentWallet = DecredWallet(
        currentWalletInfo, password, this.unspentCoinsInfoSource, libwallet!, closeLibwallet);

    await currentWallet.renameWalletFiles(newName);

    final newWalletInfo = currentWalletInfo;
    newWalletInfo.id = WalletBase.idFor(newName, getType());
    newWalletInfo.name = newName;
    newWalletInfo.dirPath = "";
    newWalletInfo.path = "";

    await walletInfoSource.put(currentWalletInfo.key, newWalletInfo);
  }

  @override
  Future<DecredWallet> restoreFromSeed(DecredRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    await this.init();
    final network = isTestnet == true ? testnet : mainnet;
    final dirPath = await pathForWalletDir(name: credentials.walletInfo!.name, type: getType());
    final config = {
      "name": credentials.walletInfo!.name,
      "datadir": dirPath,
      "pass": credentials.password!,
      "mnemonic": credentials.mnemonic,
      "net": network,
      "unsyncedaddrs": true,
    };
    await libwallet!.createWallet(jsonEncode(config));
    final di = DerivationInfo(
        derivationPath: isTestnet == true ? seedRestorePathTestnet : seedRestorePath);
    credentials.walletInfo!.derivationInfo = di;
    credentials.walletInfo!.network = network;
    credentials.walletInfo!.dirPath = "";
    credentials.walletInfo!.path = "";
    final wallet = DecredWallet(credentials.walletInfo!, credentials.password!,
        this.unspentCoinsInfoSource, libwallet!, closeLibwallet);
    await wallet.init();
    return wallet;
  }

  // restoreFromKeys only supports restoring a watch only wallet from an account
  // pubkey.
  @override
  Future<DecredWallet> restoreFromKeys(DecredRestoreWalletFromPubkeyCredentials credentials,
      {bool? isTestnet}) async {
    await this.init();
    final network = isTestnet == true ? testnet : mainnet;
    final dirPath = await pathForWalletDir(name: credentials.walletInfo!.name, type: getType());
    final config = {
      "name": credentials.walletInfo!.name,
      "datadir": dirPath,
      "pubkey": credentials.pubkey,
      "net": network,
      "unsyncedaddrs": true,
    };
    await libwallet!.createWatchOnlyWallet(jsonEncode(config));
    final di = DerivationInfo(
        derivationPath: isTestnet == true ? pubkeyRestorePathTestnet : pubkeyRestorePath);
    credentials.walletInfo!.derivationInfo = di;
    credentials.walletInfo!.network = network;
    credentials.walletInfo!.dirPath = "";
    credentials.walletInfo!.path = "";
    final wallet = DecredWallet(credentials.walletInfo!, credentials.password!,
        this.unspentCoinsInfoSource, libwallet!, closeLibwallet);
    await wallet.init();
    return wallet;
  }

  @override
  Future<DecredWallet> restoreFromHardwareWallet(
          DecredRestoreWalletFromHardwareCredentials credentials) async =>
      throw UnimplementedError();
}
