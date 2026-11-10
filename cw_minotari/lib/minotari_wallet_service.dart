import 'dart:io';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_ffi.dart';
import 'package:cw_minotari/src/rust/api/height.dart' show birthdayFromHeight;
import 'package:cw_minotari/src/rust/api/network.dart';

/// Encryption utils for Minotari - always use XChaCha20 (no legacy wallet support needed)
final _encryptionFileUtils = encryptionFileUtilsFor(true);

class MinotariWalletService extends WalletService<
    MinotariNewWalletCredentials,
    MinotariRestoreWalletFromSeedCredentials,
    MinotariRestoreWalletFromKeysCredentials,
    MinotariNewWalletCredentials> {
  MinotariWalletService();

  @override
  WalletType getType() => WalletType.minotari;

  Future<MinotariFfi> _ffiFor(String walletName, TariNetwork network) async {
    await MinotariFfi.ensureProcessNetwork(network);
    final dbPath = '${await pathForWalletTypeDir(type: getType())}/wallet.db';
    return MinotariFfi(dataPath: dbPath, walletName: walletName, network: network);
  }

  /// Opens a wallet just added to the database and writes its .keys file.
  Future<MinotariWallet> _openNew(
    WalletCredentials credentials,
    TariNetwork network, {
    required String dbPassphrase,
    String? viewPrivateKeyHex,
    String? spendPublicKeyHex,
  }) async {
    final walletInfo = credentials.walletInfo!;
    walletInfo.network = network.name;
    await walletInfo.save();

    final wallet = MinotariWallet(
      walletInfo,
      await walletInfo.getDerivationInfo(),
      password: credentials.password!,
      dbPassphrase: dbPassphrase,
      encryptionFileUtils: _encryptionFileUtils,
      viewPrivateKeyHex: viewPrivateKeyHex,
      spendPublicKeyHex: spendPublicKeyHex,
    );
    await wallet.init();
    await wallet.save();
    return wallet;
  }

  @override
  Future<WalletBase> create(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final network = minotariNetworkFor(isTestnet: isTestnet);
    final passphrase = randomMinotariPassphrase();
    await (await _ffiFor(credentials.name, network)).create(passphrase: passphrase);
    return _openNew(credentials, network, dbPassphrase: passphrase);
  }

  @override
  Future<WalletBase> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    final keysData = await WalletKeysFile.readKeysFile(
      name,
      getType(),
      password,
      _encryptionFileUtils,
    );

    final wallet = MinotariWallet(
      walletInfo,
      await walletInfo.getDerivationInfo(),
      password: password,
      dbPassphrase: keysData.passphrase ?? '',
      encryptionFileUtils: _encryptionFileUtils,
      viewPrivateKeyHex: keysData.scanSecret,
      spendPublicKeyHex: keysData.spendPubkey,
    );
    await wallet.init();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    // Locks the wallet for every holder and stops its scans before deleting it.
    final typeDir = await pathForWalletTypeDir(type: getType());
    await MinotariFfi(
      dataPath: '$typeDir/wallet.db',
      walletName: wallet,
      network: minotariNetworkFromName(walletInfo.network),
    ).delete();

    final path = await pathForWalletDir(name: wallet, type: getType());
    final dir = Directory(path);

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    await WalletInfo.delete(walletInfo);
    printV('[MinotariWalletService] Deleted wallet "$wallet"');
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }

    // Renaming needs no database session, so no passphrase.
    final currentWallet = MinotariWallet(
      currentWalletInfo,
      await currentWalletInfo.getDerivationInfo(),
      password: password,
      dbPassphrase: '',
      encryptionFileUtils: _encryptionFileUtils,
    );

    await currentWallet.renameWalletFiles(newName);

    currentWalletInfo.id = WalletBase.idFor(newName, getType());
    currentWalletInfo.name = newName;

    await currentWalletInfo.save();
  }

  /// A spend private key restores a spendable wallet; without it the wallet is
  /// watch-only (view private key and spend public key).
  @override
  Future<WalletBase> restoreFromKeys(
    MinotariRestoreWalletFromKeysCredentials credentials, {
    bool? isTestnet,
  }) async {
    final network = minotariNetworkFor(isTestnet: isTestnet);
    final passphrase = randomMinotariPassphrase();
    final ffi = await _ffiFor(credentials.name, network);
    final birthday =
        birthdayFromHeight(network: network, height: BigInt.from(credentials.height ?? 0));
    final spendPrivateKeyHex = credentials.spendPrivateKeyHex;
    final isWatchOnly = spendPrivateKeyHex == null || spendPrivateKeyHex.isEmpty;

    final details = isWatchOnly
        ? await ffi.importViewOnly(
            viewPrivateKeyHex: credentials.viewPrivateKeyHex,
            spendPublicKeyHex: credentials.spendPublicKeyHex ?? '',
            birthday: birthday,
            passphrase: passphrase,
          )
        : await ffi.importFromKeys(
            viewPrivateKeyHex: credentials.viewPrivateKeyHex,
            spendPrivateKeyHex: spendPrivateKeyHex,
            birthday: birthday,
            passphrase: passphrase,
          );

    credentials.walletInfo!.isWatchOnly = isWatchOnly;
    return _openNew(
      credentials,
      network,
      dbPassphrase: passphrase,
      viewPrivateKeyHex: details.viewPrivateKeyHex,
      spendPublicKeyHex: details.spendPublicKeyHex,
    );
  }

  @override
  Future<WalletBase> restoreFromSeed(
    MinotariRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    final network = minotariNetworkFor(isTestnet: isTestnet);
    final passphrase = randomMinotariPassphrase();
    await (await _ffiFor(credentials.name, network))
        .restore(credentials.mnemonic, passphrase: passphrase);
    return _openNew(credentials, network, dbPassphrase: passphrase);
  }

  @override
  Future<WalletBase> restoreFromHardwareWallet(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) =>
      throw UnsupportedError('Minotari does not support hardware wallets');

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final typeDir = await pathForWalletTypeDir(type: getType());
      return File('$typeDir/$name/$name.keys').existsSync();
    } catch (_) {
      return false;
    }
  }
}

class MinotariNewWalletCredentials extends WalletCredentials {
  MinotariNewWalletCredentials({
    required String name,
    String? password,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);
}

class MinotariRestoreWalletFromSeedCredentials extends WalletCredentials {
  MinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    required int height,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, height: height, walletInfo: walletInfo);

  final String mnemonic;
}

class MinotariRestoreWalletFromKeysCredentials extends WalletCredentials {
  MinotariRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required this.viewPrivateKeyHex,
    this.spendPrivateKeyHex,
    this.spendPublicKeyHex,
    required int height,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, height: height, walletInfo: walletInfo);

  final String viewPrivateKeyHex;
  final String? spendPrivateKeyHex;
  final String? spendPublicKeyHex;
}
