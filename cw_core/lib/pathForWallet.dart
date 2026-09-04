import "dart:io";
import "package:cw_core/root_dir.dart";
import "package:cw_core/wallet_type.dart";
import "package:path/path.dart" as p;

/// Shared root directory for all wallets of [type] (e.g. `wallets/bitcoin/`),
/// not one specific wallet's folder. Every wallet of this type is a flat
/// sibling here regardless of group — grouping doesn't affect disk layout.
/// Creates the directory if missing.
Future<String> pathForWalletTypeDir({required WalletType type}) async {
  final root = await getAppDir();
  final prefix = walletTypeToString(type).toLowerCase();
  final walletsDir = Directory("${root.path}/wallets");
  final walletDir = Directory("${walletsDir.path}/$prefix");

  if (!walletDir.existsSync()) {
    walletDir.createSync(recursive: true);
  }

  return walletDir.path;
}

/// One wallet's own directory, nested inside [pathForWalletTypeDir] — e.g.
/// `wallets/bitcoin/3fa1c2e0-.../`. Keyed by [id] (WalletInfo.id), never by name
/// so that renaming a wallet doesn't require moving files around. Creates the
/// directory if missing.
Future<String> pathForWalletDir({required String id, required WalletType type}) async {
  final typeRoot = await pathForWalletTypeDir(type: type);
  final walletDir = Directory("$typeRoot/$id");

  if (!walletDir.existsSync()) {
    walletDir.createSync(recursive: true);
  }

  return walletDir.path;
}

Future<String> pathForWallet({required String id, required WalletType type}) async =>
    await pathForWalletDir(id: id, type: type).then((path) => "$path/$id");


Future<String> outdatedAndroidPathForWalletDir({required String name}) async {
  final directory = await getAppDir();
  final pathDir = '${directory.path}/$name';

  return pathDir;
}
