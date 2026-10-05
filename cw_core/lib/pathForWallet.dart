import "dart:io";
import "package:cw_core/root_dir.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:path/path.dart" as p;
import "package:uuid/uuid.dart";

// New wallets have a UUID id; legacy wallets have "<type>_<name>"
bool isUuidWallet(WalletInfo info) => Uuid.isValidUUID(fromString: info.id);

// Folder name on disk: the UUID for new wallets, the name for legacy ones
String _dirNameOf(WalletInfo info) => isUuidWallet(info) ? info.id : info.name;

//<appDir>/wallets/<type>
Future<String> pathForWalletTypeDir({required WalletType type}) async {
  final root = await getAppDir();
  final prefix = walletTypeToString(type).toLowerCase();

  final walletDir = Directory(p.join(root.path, "wallets", prefix));

  if (!walletDir.existsSync()) {
    walletDir.createSync(recursive: true);
  }

  return walletDir.path;
}

// <appDir>/wallets/<type>/<dirName>
Future<String> _pathForWalletDir({required String dirName, required WalletType type}) async {
  final typeRoot = await pathForWalletTypeDir(type: type);

  final walletDir = Directory(p.join(typeRoot, dirName));

  if (!walletDir.existsSync()) {
    walletDir.createSync(recursive: true);
  }

  return walletDir.path;
}

// resolver: <appDir>/wallets/<type>/<name or uuid>
Future<String> pathForWalletDirOf(WalletInfo info) async {
  final dirName = _dirNameOf(info);
  return _pathForWalletDir(dirName: dirName, type: info.type);
}

// <appDir>/wallets/<type>/<dirName>/<dirName>
Future<String> _pathForWallet({required String dirName, required WalletType type}) async {
  final walletDir = await _pathForWalletDir(dirName: dirName, type: type);
  return p.join(walletDir, dirName);
}

// resolver: legacy wallets use the name, new wallets use the UUID
Future<String> pathForWalletOf(WalletInfo info) async {
  final dirName = _dirNameOf(info);
  return _pathForWallet(dirName: dirName, type: info.type);
}

Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
  final directory = await getAppDir();
  return p.join(directory.path, name);
}
