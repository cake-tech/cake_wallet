import "dart:io";
import "package:cw_core/exceptions/cake_exception.dart";
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

// pathForWallet.dart: path only, no side effects
Future<String> walletDirPathOf(WalletInfo info) async =>
    p.join(await pathForWalletTypeDir(type: info.type), _dirNameOf(info));

// <appDir>/wallets/<type>/<dirName>/<dirName> — path only, no side effects
Future<String> walletFilePathOf(WalletInfo info) async =>
    p.join(await walletDirPathOf(info), _dirNameOf(info));

Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
  final directory = await getAppDir();
  return p.join(directory.path, name);
}

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
