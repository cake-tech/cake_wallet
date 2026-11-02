import "dart:io";

import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:path/path.dart" as p;
import "package:uuid/uuid.dart";

/// Wallet folder layout:
///   new wallets:    <appDir>/wallets/<type>/<uuid>/<uuid>
///   legacy wallets: <appDir>/wallets/<type>/<name>/<name>
///
/// Functions named `pathFor…` create the directory (use them before writing files).
/// Functions named `wallet…PathOf` only build the path (use them for reads, checks, deletes).

/// New wallets have a UUID id; legacy wallets have "<type>_<name>".
bool isUuidWallet(WalletInfo info) => Uuid.isValidUUID(fromString: info.id);

/// Folder name on disk: the UUID for new wallets, the name for legacy ones.
/// Throws on a name that would resolve outside the wallet's own folder.
String _dirNameOf(WalletInfo info) {
  final dirName = isUuidWallet(info) ? info.id : info.name;
  final isUnsafe = dirName.trim().isEmpty ||
      dirName == "." ||
      dirName == ".." ||
      dirName.contains("/") ||
      dirName.contains(p.separator);

  if (isUnsafe) {
    throw ArgumentError.value(dirName, "dirName", "Invalid wallet folder name (id: ${info.id})");
  }
  return dirName;
}

/// <appDir>/wallets/<type> — always created.
Future<String> pathForWalletTypeDir({required WalletType type}) async {
  final root = await getAppDir();
  final dir = Directory(p.join(root.path, "wallets", walletTypeToString(type).toLowerCase()));

  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir.path;
}

// ---- Path only (no side effects besides the type root) ---------------------

/// <appDir>/wallets/<type>/<dirName>
Future<String> walletDirPathOf(WalletInfo info) async =>
    p.join(await pathForWalletTypeDir(type: info.type), _dirNameOf(info));

/// <appDir>/wallets/<type>/<dirName>/<dirName>
Future<String> walletFilePathOf(WalletInfo info) async =>
    p.join(await walletDirPathOf(info), _dirNameOf(info));

// ---- Creates the wallet directory -------------------------------------------

/// Like [walletDirPathOf], but creates the directory.
Future<String> pathForWalletDirOf(WalletInfo info) async {
  final dir = Directory(await walletDirPathOf(info));

  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir.path;
}

/// Like [walletFilePathOf], but creates the wallet directory.
Future<String> pathForWalletOf(WalletInfo info) async =>
    p.join(await pathForWalletDirOf(info), _dirNameOf(info));

// ---- Legacy ------------------------------------------------------------------

Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
  final directory = await getAppDir();
  return p.join(directory.path, name);
}

// ---- Deprecated: wallet files are stored by id and no longer move -----------

@Deprecated("Wallet files are stored by id and never move. Will be removed with rename().")
Future<void> copyWalletFilesTo({
  required String fromName,
  required String toName,
  required WalletType type,
}) async {
  if (fromName == toName) return;

  final typeRoot = await pathForWalletTypeDir(type: type);
  final sourceDir = Directory(p.join(typeRoot, fromName));
  if (!sourceDir.existsSync()) {
    throw WalletNotFoundException(name: fromName, type: type);
  }

  if (Directory(p.join(typeRoot, toName)).existsSync()) {
    throw WalletExistsException('Cannot rename wallet: "$toName" already exists');
  }

  final destinationDir = Directory(p.join(typeRoot, toName));
  await _copyDirectory(sourceDir, destinationDir);

  for (final suffix in const ['', '.keys', '.keys.backup']) {
    final file = File(p.join(destinationDir.path, '$fromName$suffix'));
    if (file.existsSync()) {
      await file.rename(p.join(destinationDir.path, '$toName$suffix'));
    }
  }
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final name = p.basename(entity.path);
    if (entity is File) {
      await entity.copy(p.join(destination.path, name));
    } else if (entity is Directory) {
      await _copyDirectory(entity, Directory(p.join(destination.path, name)));
    }
  }
}
