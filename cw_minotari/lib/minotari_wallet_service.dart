import 'dart:io';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_ffi.dart';
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

  TariNetwork _getNetwork(bool? isTestnet) {
    return isTestnet == true ? TariNetwork.esmeralda : TariNetwork.mainNet;
  }

  @override
  Future<WalletBase> create(
    MinotariNewWalletCredentials credentials, {
    bool? isTestnet,
  }) async {
    final path = await pathForWallet(
      name: credentials.name,
      type: getType(),
    );

    final ffi = MinotariFfi(dataPath: path);
    final passphrase = credentials.passphrase ?? '';

    // Create wallet - get WalletCreationDetails with seed words
    final network = _getNetwork(isTestnet);
    final walletInfo = credentials.walletInfo!;
    final walletDetails = await ffi.create(network, passphrase: passphrase);

    // Extract seed words from WalletCreationDetails
    final seedWords = walletDetails.seedWords.words;
    final mnemonic = seedWords.join(' ');

    // Save network to wallet info
    walletInfo.network = network.name;
    await walletInfo.save();

    // Get and set the wallet address
    final address = await ffi.getAddress(passphrase: passphrase);

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

    // Initialize wallet (this will open the database created above)
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
    );
    await wallet.init();

    return wallet;
  }

  @override
  Future<void> remove(String wallet) async {
    final path = await pathForWalletDir(name: wallet, type: getType());
    final file = Directory(path);

    if (await file.exists()) {
      await file.delete(recursive: true);
    }

    final walletInfo = await WalletInfo.get(wallet, getType());
    if (walletInfo == null) {
      throw Exception('Wallet not found');
    }
    await WalletInfo.delete(walletInfo);
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

    currentWalletInfo.name = newName;

    await currentWalletInfo.save();
  }

  @override
  Future<WalletBase> restoreFromKeys(
    MinotariRestoreWalletFromKeysCredentials credentials, {
    bool? isTestnet,
  }) async {
    // Minotari uses mnemonic-based restoration
    throw UnimplementedError('Minotari wallets use mnemonic-based restoration');
  }

  /// TODO : Need to generate a random passphrase if none is provided
  @override
  Future<WalletBase> restoreFromSeed(
    MinotariRestoreWalletFromSeedCredentials credentials, {
    bool? isTestnet,
  }) async {
    final path = await pathForWallet(
      name: credentials.name,
      type: getType(),
    );

    final ffi = MinotariFfi(dataPath: path);
    final passphrase = credentials.passphrase ?? '';
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

    // Initialize wallet (this will open the database with restored data)
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
      final path = await pathForWallet(name: name, type: getType());
      return File(path).existsSync();
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
    required this.language,
    WalletInfo? walletInfo,
  }) : super(name: name, password: password, walletInfo: walletInfo);

  final String language;
}
