import 'dart:io';
import 'dart:math';
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
import 'package:cw_minotari/src/rust/api/network.dart';
import 'package:cw_minotari/src/rust/api/wallet.dart' show deleteWallet;

/// Encryption utils for Minotari - always use XChaCha20 (no legacy wallet support needed)
final _encryptionFileUtils = encryptionFileUtilsFor(true);

extension _PassphraseExtension on String? {
  String getOrGenerateRandom() {
    if (this != null && this!.isNotEmpty) return this!;

    const allowedChars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%-=_+[]{}|;:,.<>?';
    final random = Random.secure();
    final buffer = StringBuffer();

    for (int i = 0; i < 32; i++) {
      buffer.write(allowedChars[random.nextInt(allowedChars.length)]);
    }

    return buffer.toString();
  }
}

class MinotariWalletService extends WalletService<
    MinotariNewWalletCredentials,
    MinotariRestoreWalletFromSeedCredentials,
    MinotariRestoreWalletFromKeysCredentials,
    MinotariNewWalletCredentials> {
  MinotariWalletService();

  @override
  WalletType getType() => WalletType.minotari;

  TariNetwork _getNetwork(bool? isTestnet) {
    return isTestnet == true ? TariNetwork.esmeralda : TariNetwork.mainNet;
  }

  @override
  Future<WalletBase> create(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final dbPath = '${await pathForWalletTypeDir(type: getType())}/wallet.db';

    final ffi = MinotariFfi(dataPath: dbPath, walletName: credentials.name);
    final passphrase = credentials.passphrase.getOrGenerateRandom();

    // Create wallet - get WalletCreationDetails with seed words
    final network = _getNetwork(isTestnet);
    final walletInfo = credentials.walletInfo!;
    final walletDetails = await ffi.create(network, passphrase: passphrase);

    // Extract seed words from WalletCreationDetails
    final seedWords = walletDetails.seedWords!.words;
    final mnemonic = seedWords.join(' ');

    // Save network to wallet info
    walletInfo.network = network.name;
    await walletInfo.save();

    // Get and set the wallet address
    final address = await ffi.getAddress(passphrase: passphrase);

    // Dispose the temporary FFI - wallet.init() will create its own
    await ffi.dispose();

    // Now create the wallet instance with the mnemonic
    final derivationInfo = await walletInfo.getDerivationInfo();
    final wallet = MinotariWallet(
      walletInfo,
      derivationInfo,
      mnemonic: mnemonic,
      password: credentials.password!,
      passphrase: passphrase,
      encryptionFileUtils: _encryptionFileUtils,
    );
    wallet.walletAddresses.setAddress(address);

    // Initialize wallet (this will open the database fresh)
    await wallet.init();

    // Save wallet (this will save the keys file with mnemonic)
    await wallet.save();

    return wallet;
  }

  @override
  Future<WalletBase> openWallet(String name, String password) async {
    final walletInfo = await WalletInfo.get(name, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }

    // Load wallet keys (mnemonic) from encrypted .keys file
    final keysData = await WalletKeysFile.readKeysFile(
      name,
      getType(),
      password,
      _encryptionFileUtils,
    );

    // Ensure passphrase is never null - convert to empty string for consistency
    // This is needed for both new wallets and existing wallets that may have null stored
    final passphrase = keysData.passphrase ?? '';
    final derivationInfo = await walletInfo.getDerivationInfo();
    final wallet = MinotariWallet(
      walletInfo,
      derivationInfo,
      mnemonic: keysData.mnemonic,
      passphrase: passphrase,
      password: password,
      encryptionFileUtils: _encryptionFileUtils,
      viewPrivateKeyHex: keysData.scanSecret,
      spendPublicKeyHex: keysData.spendPubkey,
    );
    await wallet.init();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    try {
      await deleteWallet(walletName: wallet);
      printV('[MinotariWalletService] Successfully removed wallet "$wallet" from database');
    } catch (e) {
      printV('[MinotariWalletService] Failed to delete wallet from database: $e');
      printV('[MinotariWalletService] Wallet deletion aborted!');
      rethrow; // Rethrow the exception to indicate failure to the caller
    }

    final path = await pathForWalletDir(name: wallet, type: getType());
    final dir = Directory(path);

    if (await dir.exists()) {
      await dir.delete(recursive: true);
      printV('[MinotariWalletService] Deleted wallet directory: $path');
    }

    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);
    printV('[MinotariWalletService] Deleted wallet info for "$wallet"');
  }

  @override
  Future<void> rename(String currentName, String password, String newName) async {
    final currentWalletInfo = await WalletInfo.get(currentName, getType());
    if (currentWalletInfo == null) {
      throw Exception('Wallet not found');
    }

    final derivationInfo = await currentWalletInfo.getDerivationInfo();
    final currentWallet = MinotariWallet(
      currentWalletInfo,
      derivationInfo,
      password: password,
      encryptionFileUtils: _encryptionFileUtils,
    );

    await currentWallet.renameWalletFiles(newName);

    currentWalletInfo.id = WalletBase.idFor(newName, getType());
    currentWalletInfo.name = newName;

    await currentWalletInfo.save();
  }

  @override
  Future<WalletBase> restoreFromKeys(
    MinotariRestoreWalletFromKeysCredentials credentials, {
    bool? isTestnet,
  }) async {
    final dbPath = '${await pathForWalletTypeDir(type: getType())}/wallet.db';

    final ffi = MinotariFfi(dataPath: dbPath, walletName: credentials.name);
    final passphrase = credentials.passphrase.getOrGenerateRandom();
    final walletInfo = credentials.walletInfo!;
    final network = _getNetwork(isTestnet);

    await ffi.importViewOnly(
      viewPrivateKeyHex: credentials.viewPrivateKeyHex,
      spendPublicKeyHex: credentials.spendPublicKeyHex,
      birthday: credentials.height ?? 0,
      passphrase: passphrase,
      network: network,
    );

    walletInfo.network = network.name;
    await walletInfo.save();

    // Get and set the wallet address
    final address = await ffi.getAddress(passphrase: passphrase);

    // Dispose the temporary FFI - wallet.init() will create its own
    await ffi.dispose();

    final derivationInfo = await walletInfo.getDerivationInfo();
    final wallet = MinotariWallet(
      walletInfo,
      derivationInfo,
      password: credentials.password!,
      passphrase: passphrase,
      encryptionFileUtils: _encryptionFileUtils,
      viewPrivateKeyHex: credentials.viewPrivateKeyHex,
      spendPublicKeyHex: credentials.spendPublicKeyHex,
    );
    wallet.walletAddresses.setAddress(address);

    await wallet.init();
    await wallet.save();

    return wallet;
  }

  @override
  Future<WalletBase> restoreFromSeed(
    MinotariRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    final dbPath = '${await pathForWalletTypeDir(type: getType())}/wallet.db';

    final ffi = MinotariFfi(dataPath: dbPath, walletName: credentials.name);
    final passphrase = credentials.passphrase.getOrGenerateRandom();
    final walletInfo = credentials.walletInfo!;

    // Restore wallet from mnemonic - get WalletCreationDetails with seed words
    final network = _getNetwork(isTestnet);
    await ffi.restore(
      credentials.mnemonic,
      network,
      passphrase: passphrase,
    );

    // Save network to wallet info
    walletInfo.network = network.name;
    await walletInfo.save();

    // Get and set the wallet address
    final address = await ffi.getAddress(passphrase: passphrase);

    // Dispose the temporary FFI - wallet.init() will create its own
    await ffi.dispose();

    // Now create the wallet instance with the mnemonic
    final derivationInfo = await walletInfo.getDerivationInfo();
    final wallet = MinotariWallet(
      walletInfo,
      derivationInfo,
      mnemonic: credentials.mnemonic,
      password: credentials.password!,
      passphrase: passphrase,
      encryptionFileUtils: _encryptionFileUtils,
    );
    wallet.walletAddresses.setAddress(address);

    // Initialize wallet (this will open the database fresh)
    await wallet.init();

    // Save wallet (this will save the keys file with mnemonic)
    await wallet.save();

    return wallet;
  }

  @override
  Future<WalletBase> restoreFromHardwareWallet(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    // Minotari doesn't support hardware wallets yet
    throw UnimplementedError('Minotari hardware wallet support not yet implemented');
  }

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
    String? passphrase,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo, passphrase: passphrase);
}

class MinotariRestoreWalletFromSeedCredentials extends WalletCredentials {
  MinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required this.mnemonic,
    required int height,
    String? passphrase,
    WalletInfo? walletInfo,
  }) : super(
         name: name,
         password: password,
         height: height,
         walletInfo: walletInfo,
         passphrase: passphrase,
       );

  final String mnemonic;
}

class MinotariRestoreWalletFromKeysCredentials extends WalletCredentials {
  MinotariRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required this.viewPrivateKeyHex,
    required this.spendPublicKeyHex,
    required int birthday,
    String? passphrase,
    WalletInfo? walletInfo,
  }) : super(
          name: name,
          password: password,
          height: birthday,
          walletInfo: walletInfo,
          passphrase: passphrase,
        );

  final String viewPrivateKeyHex;
  final String spendPublicKeyHex;
}
