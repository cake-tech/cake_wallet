import "dart:io";

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
/// Throws on a name that would resolve to the type folder or outside it.
/// Whitespace-only legacy names are valid folder names, except on Windows, which strips
/// trailing spaces and dots (so "   " or "..." would be the type folder itself).
String _dirNameOf(WalletInfo info) {
  final dirName = isUuidWallet(info) ? info.id : info.name;
  final isUnsafe = dirName.isEmpty ||
      dirName == "." ||
      dirName == ".." ||
      dirName.contains("/") ||
      dirName.contains(p.separator) ||
      (Platform.isWindows && dirName.replaceAll(RegExp(r"[ .]+$"), "").isEmpty);

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
