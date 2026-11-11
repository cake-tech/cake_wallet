import 'dart:io';

import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/exceptions/cake_exception.dart';
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
import 'package:cw_minotari/minotari_send_notes.dart';
import 'package:cw_minotari/src/rust/api/height.dart' show birthdayFromHeight;
import 'package:cw_minotari/src/rust/api/wallet.dart' show WalletCreationDetails;
import 'package:path/path.dart' as p;

/// Encryption utils for Minotari - always use XChaCha20 (no legacy wallet support needed)
final _encryptionFileUtils = encryptionFileUtilsFor(true);

/// Copies a wallet's .keys and .keys.backup, and its send notes, from [fromPath] to [toPath]
/// and returns the copies. Never overwrites: files already at [toPath] may be the only way to
/// unlock a leftover account's seed.
Future<List<File>> copyMinotariKeysFiles({
  required String fromPath,
  required String toPath,
}) async {
  const suffixes = ['.keys', '.keys.backup', minotariSendNotesSuffix];
  if (suffixes.any((suffix) => File('$toPath$suffix').existsSync())) {
    throw WalletExistsException('Wallet files already exist at $toPath.');
  }

  await Directory(File(toPath).parent.path).create(recursive: true);
  final copies = <File>[];
  for (final suffix in suffixes) {
    final keysFile = File('$fromPath$suffix');
    if (keysFile.existsSync()) copies.add(await keysFile.copy('$toPath$suffix'));
  }
  return copies;
}

/// What restores a wallet imported from keys, labelled like the keys page's QR fields:
/// the view and spend private keys, or for a watch-only wallet the spend public key.
String minotariKeysRecoveryText(WalletKeysData keysData) => [
      'view_key: ${keysData.scanSecret}',
      if (keysData.privateKey != null)
        'spend_key: ${keysData.privateKey}'
      else
        'spend_pubkey: ${keysData.spendPubkey}',
    ].join('\n');

class MinotariWalletService extends WalletService<
    MinotariNewWalletCredentials,
    MinotariRestoreWalletFromSeedCredentials,
    MinotariRestoreWalletFromKeysCredentials,
    MinotariNewWalletCredentials> {
  MinotariWalletService();

  @override
  WalletType getType() => WalletType.minotari;

  Future<MinotariFfi> _ffiFor(String walletName) async {
    final dbPath = p.join(await pathForWalletTypeDir(type: getType()), 'wallet.db');
    return MinotariFfi(dataPath: dbPath, walletName: walletName);
  }

  /// Adds the account with [addAccount], writes its .keys files and opens it. Without its
  /// .keys files nothing can unlock the account, so it is deleted if they can't be written.
  ///
  /// An account already under this name is never deleted: after a crash a half-created
  /// account can't be told from a real one whose .keys files went missing, and the database
  /// may hold the only copy of its seed. The name is refused instead.
  Future<MinotariWallet> _addWallet(
    WalletCredentials credentials,
    Future<WalletCreationDetails> Function(MinotariFfi ffi, String passphrase) addAccount, {
    bool keepKeys = false,
    String? spendPrivateKeyHex,
  }) async {
    final ffi = await _ffiFor(credentials.name);
    if (await ffi.exists()) {
      throw WalletExistsException(
          'The Minotari wallet database already has a wallet named "${credentials.name}".');
    }

    final passphrase = randomMinotariPassphrase();
    final details = await addAccount(ffi, passphrase);
    // The seed is read on demand later; drop cw's copy now (zeroized on drop).
    details.seedWords?.dispose();

    final walletInfo = credentials.walletInfo!;
    final wallet = MinotariWallet(
      walletInfo,
      await walletInfo.getDerivationInfo(),
      password: credentials.password!,
      dbPassphrase: passphrase,
      encryptionFileUtils: _encryptionFileUtils,
      viewPrivateKeyHex: keepKeys ? details.viewPrivateKeyHex : null,
      spendPublicKeyHex: keepKeys ? details.spendPublicKeyHex : null,
    );
    try {
      await wallet.writeKeysFiles(credentials.password!, spendPrivateKeyHex: spendPrivateKeyHex);
    } catch (_) {
      await ffi.delete();
      rethrow;
    }

    walletInfo.network = MinotariFfi.network.name;
    await walletInfo.save();
    await wallet.init();
    return wallet;
  }

  @override
  Future<WalletBase> create(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) {
    return _addWallet(
      credentials,
      (ffi, passphrase) => ffi.create(passphrase: passphrase),
    );
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
    // Locks the wallet for every holder and stops its scans before deleting it. Without an
    // account (a create that never finished) the files and WalletInfo still go.
    final ffi = await _ffiFor(wallet);
    if (await ffi.exists()) await ffi.delete();

    final path = await pathForWalletDir(name: wallet, type: getType());
    final dir = Directory(path);

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // The files are already gone; a missing WalletInfo must not make the delete look failed.
    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      printV('[MinotariWalletService] No WalletInfo for deleted wallet "$wallet"');
    } else {
      await WalletInfo.delete(walletInfo);
    }
    printV('[MinotariWalletService] Deleted wallet "$wallet"');
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    // The old directory is deleted at the end; with the same name that is the wallet's own.
    if (currentName == newName) return;

    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }

    final typeDir = await pathForWalletTypeDir(type: getType());
    final newPath = p.join(typeDir, newName, newName);
    if (Directory(p.join(typeDir, newName)).existsSync()) {
      throw WalletExistsException('A Minotari wallet directory named "$newName" already exists.');
    }
    if (await (await _ffiFor(newName)).exists()) {
      throw WalletExistsException(
          'The Minotari wallet database already has a wallet named "$newName".');
    }

    // The .keys files are copied before the account is renamed, so the account is never under
    // a name without them; a failed rename removes the copies.
    final copies = await copyMinotariKeysFiles(
      fromPath: await pathForWallet(name: currentName, type: getType()),
      toPath: newPath,
    );
    try {
      await (await _ffiFor(currentName)).rename(newWalletName: newName);
    } catch (_) {
      for (final copy in copies) {
        await copy.delete();
      }
      rethrow;
    }

    currentWalletInfo.id = WalletBase.idFor(newName, getType());
    currentWalletInfo.name = newName;
    await currentWalletInfo.save();

    await Directory(await pathForWalletDir(name: currentName, type: getType())).delete(
      recursive: true,
    );
  }

  /// A spend private key restores a spendable wallet; without it the wallet is
  /// watch-only (view private key and spend public key).
  @override
  Future<WalletBase> restoreFromKeys(
    MinotariRestoreWalletFromKeysCredentials credentials, {
    bool? isTestnet,
  }) {
    final spendPrivateKeyHex = credentials.spendPrivateKeyHex;
    final isWatchOnly = spendPrivateKeyHex == null || spendPrivateKeyHex.isEmpty;
    credentials.walletInfo!.isWatchOnly = isWatchOnly;

    return _addWallet(credentials,
        keepKeys: true,
        spendPrivateKeyHex: isWatchOnly ? null : spendPrivateKeyHex, (ffi, passphrase) {
      final birthday = birthdayFromHeight(
          network: MinotariFfi.network, height: BigInt.from(credentials.height ?? 0));
      return isWatchOnly
          ? ffi.importViewOnly(
              viewPrivateKeyHex: credentials.viewPrivateKeyHex,
              spendPublicKeyHex: credentials.spendPublicKeyHex ?? '',
              birthday: birthday,
              passphrase: passphrase,
            )
          : ffi.importFromKeys(
              viewPrivateKeyHex: credentials.viewPrivateKeyHex,
              spendPrivateKeyHex: spendPrivateKeyHex,
              birthday: birthday,
              passphrase: passphrase,
            );
    });
  }

  @override
  Future<WalletBase> restoreFromSeed(
    MinotariRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) {
    return _addWallet(
      credentials,
      (ffi, passphrase) => ffi.restore(credentials.mnemonic, passphrase: passphrase),
    );
  }

  @override
  Future<WalletBase> restoreFromHardwareWallet(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) =>
      throw UnsupportedError('Minotari does not support hardware wallets');

  /// Corrupted-wallet recovery: the mnemonic lives only in the wallet database, opened with
  /// the passphrase from the .keys file. Wallets imported from keys have none.
  @override
  Future<String> getSeeds(String name, String password, WalletType type) async {
    try {
      final keysData =
          await WalletKeysFile.readKeysFile(name, type, password, _encryptionFileUtils);
      // Imported from keys: no mnemonic, the keys restore it.
      if (keysData.scanSecret != null) return minotariKeysRecoveryText(keysData);
      final ffi = await _ffiFor(name);
      return (await ffi.seedWords(passphrase: keysData.passphrase ?? '')).join(' ');
    } catch (_) {
      return '';
    }
  }

  /// Makes wallet.db consistent before an app backup copies it; nothing to do without one.
  @override
  Future<void> prepareForBackup() async {
    final dbPath = p.join(await pathForWalletTypeDir(type: WalletType.minotari), 'wallet.db');
    if (!File(dbPath).existsSync()) return;
    // The checkpoint doesn't depend on the wallet; any name will do.
    await MinotariFfi(dataPath: dbPath, walletName: '').checkpoint();
  }

  @override
  Future<bool> isWalletExit(String name) async {
    try {
      final typeDir = await pathForWalletTypeDir(type: getType());
      return File(p.join(typeDir, name, '$name.keys')).existsSync();
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
