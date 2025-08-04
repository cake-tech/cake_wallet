import 'dart:io';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';

String backupFileName(String originalPath) {
  final pathParts = originalPath.split('/');
  final newName = '#_${pathParts.last}';
  pathParts.removeLast();
  pathParts.add(newName);
  return pathParts.join('/');
}

Future<void> backupWalletFiles(String name) async {
  final path = await pathForWallet(name: name, type: WalletType.monero);
  final cacheFile = File(path);
  final keysFile = File('$path.keys');
  final addressListFile = File('$path.address.txt');
  final newCacheFilePath = backupFileName(cacheFile.path);
  final newKeysFilePath = backupFileName(keysFile.path);
  final newAddressListFilePath = backupFileName(addressListFile.path);

  if (cacheFile.existsSync() && !File(newCacheFilePath).existsSync()) {
    await cacheFile.copy(newCacheFilePath);
  }

  if (keysFile.existsSync() && !File(newKeysFilePath).existsSync()) {
    await keysFile.copy(newKeysFilePath);
  }

  if (addressListFile.existsSync() && !File(newAddressListFilePath).existsSync()) {
    await addressListFile.copy(newAddressListFilePath);
  }
}

Future<void> restoreWalletFiles(String name) async {
  final walletDirPath = await pathForWalletDir(name: name, type: WalletType.monero);
  final cacheFilePath = '$walletDirPath/$name';
  final keysFilePath = '$walletDirPath/$name.keys';
  final addressListFilePath = '$walletDirPath/$name.address.txt';
  final backupCacheFile = File(backupFileName(cacheFilePath));
  final backupKeysFile = File(backupFileName(keysFilePath));
  final backupAddressListFile = File(backupFileName(addressListFilePath));

  if (backupCacheFile.existsSync()) {
    await backupCacheFile.copy(cacheFilePath);
  }

  if (backupKeysFile.existsSync()) {
    await backupKeysFile.copy(keysFilePath);
  }

  if (backupAddressListFile.existsSync()) {
    await backupAddressListFile.copy(addressListFilePath);
  }
}

Future<void> resetCache(String name) async {
  await removeCache(name);

  final walletDirPath = await pathForWalletDir(name: name, type: WalletType.monero);
  final cacheFilePath = '$walletDirPath/$name';
  final backupCacheFile = File(backupFileName(cacheFilePath));
  if (backupCacheFile.existsSync()) {
    await backupCacheFile.copy(cacheFilePath);
  }
}

Future<bool> backupWalletFilesExists(String name) async {
  final walletDirPath = await pathForWalletDir(name: name, type: WalletType.monero);
  final cacheFilePath = '$walletDirPath/$name';
  final keysFilePath = '$walletDirPath/$name.keys';
  final addressListFilePath = '$walletDirPath/$name.address.txt';
  final backupCacheFile = File(backupFileName(cacheFilePath));
  final backupKeysFile = File(backupFileName(keysFilePath));
  final backupAddressListFile = File(backupFileName(addressListFilePath));

  return backupCacheFile.existsSync() &&
      backupKeysFile.existsSync() &&
      backupAddressListFile.existsSync();
}

// WARNING: Transaction keys and your Polyseed CANNOT be recovered if this file is deleted
Future<void> removeCache(String name) async {
  final path = await pathForWallet(name: name, type: WalletType.monero);
  final cacheFile = File(path);
  final backgroundCacheFile = File(path + ".background");
  if (cacheFile.existsSync()) {
    cacheFile.deleteSync();
  }
  if (backgroundCacheFile.existsSync()) {
    backgroundCacheFile.deleteSync();
  }
}

Future<void> restoreOrResetWalletFiles(String name) async {
  final backupsExists = await backupWalletFilesExists(name);

  if (backupsExists) {
    await removeCache(name);
    // TODO(mrcyjanek): is this needed?
    // If we remove cache then wallet should be restored from .keys file.
    await restoreWalletFiles(name);
  }
}
