import 'dart:io';
import 'package:cw_core/wallet_info.dart';

String backupFileName(String originalPath) {
  final pathParts = originalPath.split('/');
  final newName = '#_${pathParts.last}';
  pathParts.removeLast();
  pathParts.add(newName);
  return pathParts.join('/');
}

Future<void> backupWalletFiles(WalletInfo walletInfo) async {
  final path = walletInfo.path;
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

Future<void> restoreWalletFiles(WalletInfo walletInfo) async {
  final walletDirPath = walletInfo.dirPath;
  final cacheFilePath = walletInfo.path;
  final keysFilePath = '${walletInfo.path}.keys';
  final addressListFilePath = '${walletInfo.path}.address.txt';
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

Future<void> resetCache(WalletInfo walletInfo) async {
  await removeCache(walletInfo);

  final cacheFilePath = walletInfo.path;
  final backupCacheFile = File(backupFileName(cacheFilePath));
  if (backupCacheFile.existsSync()) {
    await backupCacheFile.copy(cacheFilePath);
  }
}

Future<bool> backupWalletFilesExists(WalletInfo walletInfo) async {
  final cacheFilePath = walletInfo.path;
  final keysFilePath = '${walletInfo.path}.keys';
  final addressListFilePath = '${walletInfo.path}.address.txt';
  final backupCacheFile = File(backupFileName(cacheFilePath));
  final backupKeysFile = File(backupFileName(keysFilePath));
  final backupAddressListFile = File(backupFileName(addressListFilePath));

  return backupCacheFile.existsSync() &&
      backupKeysFile.existsSync() &&
      backupAddressListFile.existsSync();
}

// WARNING: Transaction keys and your Polyseed CANNOT be recovered if this file is deleted
Future<void> removeCache(WalletInfo walletInfo) async {
  final path = walletInfo.path;
  final cacheFile = File(path);
  final backgroundCacheFile = File(path + ".background");
  if (cacheFile.existsSync()) {
    cacheFile.deleteSync();
  }
  if (backgroundCacheFile.existsSync()) {
    backgroundCacheFile.deleteSync();
  }
}

Future<void> restoreOrResetWalletFiles(WalletInfo walletInfo) async {
  final backupsExists = await backupWalletFilesExists(walletInfo);

  if (backupsExists) {
    await removeCache(walletInfo);
    await restoreWalletFiles(walletInfo);
  }
}