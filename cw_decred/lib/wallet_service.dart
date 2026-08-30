import 'dart:convert';
import 'dart:io';
import 'package:cw_decred/api/libdcrwallet.dart';
import 'package:cw_decred/wallet_creation_credentials.dart';
import 'package:cw_decred/wallet.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:path/path.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/unspent_coins_info.dart';

class DecredWalletService extends WalletService<
    DecredNewWalletCredentials,
    DecredRestoreWalletFromSeedCredentials,
    DecredRestoreWalletFromPubkeyCredentials,
    DecredRestoreWalletFromHardwareCredentials> {
  DecredWalletService(this.unspentCoinsInfoSource);

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
  Future<DecredWallet> create(DecredNewWalletCredentials credentials, {bool? isTestnet}) async {
    await this.init();
    final dirPath = credentials.walletInfo!.path;
    final network = isTestnet == true ? testnet : mainnet;
    final config = {
      "name": credentials.walletInfo!.name,
      "datadir": dirPath,
      "pass": credentials.password!,
      "net": network,
      "unsyncedaddrs": true,
    };
    await libwallet!.createWallet(jsonEncode(config));
    final di = await credentials.walletInfo!.getDerivationInfo();
    di.derivationPath = isTestnet == true ? seedRestorePathTestnet : seedRestorePath;
    await di.save();
    credentials.walletInfo!.save();
    credentials.walletInfo!.network = network;
    // ios will move our wallet directory when updating. Since we must
    // recalculate the new path every time we open the wallet, ensure this path
    // is not used. An older wallet will have a directory here which is a
    // condition for moving the wallet when opening, so this must be kept blank
    // going forward.
    credentials.walletInfo!.dirPath = "";
    credentials.walletInfo!.path = "";
    final wallet = DecredWallet(credentials.walletInfo!, di, credentials.password!,
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
  Future<DecredWallet> openWallet(WalletInfo walletInfo, String password) async {

    final di = await walletInfo.getDerivationInfo();
    if (walletInfo.network == null || walletInfo.network == "") {
      walletInfo.network = di.derivationPath == seedRestorePathTestnet ||
              di.derivationPath == pubkeyRestorePathTestnet
          ? testnet
          : mainnet;
      walletInfo.save();
    }

    await this.init();

    // TODO(wallet-id-refactor): this whole file always recomputes the wallet
    // dir from an identifier rather than trusting walletInfo.dirPath — see
    // create()'s comment about iOS relocating the directory. Needs a
    // deliberate decision, not resolved here: does that iOS issue still  exist?
    // If not, we can just use walletInfo.dirPath.
    final dirPath = await pathForWalletDir(id: walletInfo.id, type: getType());

    // Cake wallet version 4.27.0 and earlier gave a wallet dir that did not
    // match the name. Move those to the correct place.

    if (walletInfo.path != "") {
      // On ios the stored dir no longer exists. We can only trust the basename.
      // dirPath may already be updated and lost the basename, so look at path.
      final randomBasename = basename(walletInfo.path);
      final oldDir = await pathForWalletDir(id: randomBasename, type: getType()); // TODO: see note above — randomBasename is a legacy name, not an id
      if (oldDir != dirPath) {
        await this.moveWallet(oldDir, dirPath);
      }
      // Clear the path so this does not trigger again.
      walletInfo.dirPath = "";
      walletInfo.path = "";
      await walletInfo.save();
    }

    final config = {
      "name": walletInfo.name,
      "datadir": dirPath,
      "net": walletInfo.network,
      "unsyncedaddrs": true,
    };
    await libwallet!.loadWallet(jsonEncode(config));
    final wallet = DecredWallet(
        walletInfo, di, password, this.unspentCoinsInfoSource, libwallet!, closeLibwallet);
    await wallet.init();
    return wallet;
  }

  @override
  Future<void> rename(WalletInfo currentWalletInfo, String password, String newName) async {
    final di = await currentWalletInfo.getDerivationInfo();
    final network =
    di.derivationPath == seedRestorePathTestnet || di.derivationPath == pubkeyRestorePathTestnet
        ? testnet
        : mainnet;
    currentWalletInfo.network = network;
    await currentWalletInfo.save();

    if (libwallet == null) {
      libwallet = await Libwallet.spawn();
      libwallet!.initLibdcrwallet("", "err");
    }
    final currentWallet = DecredWallet(
        currentWalletInfo, di, password, this.unspentCoinsInfoSource, libwallet!, closeLibwallet);

    await currentWallet.renameWalletFiles(newName);

    currentWalletInfo.name = newName;
    await currentWalletInfo.save();
  }

  @override
  Future<DecredWallet> restoreFromSeed(DecredRestoreWalletFromSeedCredentials credentials,
      {bool? isTestnet}) async {
    await this.init();
    final network = isTestnet == true ? testnet : mainnet;
    final dirPath = credentials.walletInfo!.path;
    final config = {
      "name": credentials.walletInfo!.name,
      "datadir": dirPath,
      "pass": credentials.password!,
      "mnemonic": credentials.mnemonic,
      "net": network,
      "unsyncedaddrs": true,
    };
    await libwallet!.createWallet(jsonEncode(config));
    final di = await credentials.walletInfo!.getDerivationInfo();
    di.derivationPath = isTestnet == true ? seedRestorePathTestnet : seedRestorePath;
    await di.save();
    credentials.walletInfo!.network = network;
    credentials.walletInfo!.dirPath = "";
    credentials.walletInfo!.path = "";
    final wallet = DecredWallet(credentials.walletInfo!, di, credentials.password!,
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
    final dirPath = credentials.walletInfo!.path;
    final config = {
      "name": credentials.walletInfo!.name,
      "datadir": dirPath,
      "pubkey": credentials.pubkey,
      "net": network,
      "unsyncedaddrs": true,
    };
    await libwallet!.createWatchOnlyWallet(jsonEncode(config));
    final di = await credentials.walletInfo!.getDerivationInfo();
    di.derivationPath = isTestnet == true ? pubkeyRestorePathTestnet : pubkeyRestorePath;
    await di.save();
    credentials.walletInfo!.network = network;
    credentials.walletInfo!.dirPath = "";
    credentials.walletInfo!.path = "";
    final wallet = DecredWallet(credentials.walletInfo!, di, credentials.password!,
        this.unspentCoinsInfoSource, libwallet!, closeLibwallet);
    await wallet.init();
    return wallet;
  }

  @override
  Future<DecredWallet> restoreFromHardwareWallet(
          DecredRestoreWalletFromHardwareCredentials credentials) async =>
      throw UnimplementedError();
}
