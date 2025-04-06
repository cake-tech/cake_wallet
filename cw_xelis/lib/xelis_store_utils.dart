import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:cw_xelis/src/api/network.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';

Future<String> pathForXelisNetworkFile(String name) async {
  final walletDir = await pathForWalletDir(name: name, type: WalletType.xelis);
  return p.join(walletDir, 'network.txt');
}

Future<void> saveXelisNetwork(String name, Network network) async {
  final path = await pathForXelisNetworkFile(name);
  await File(path).writeAsString(network.name);
}

Future<Network> loadXelisNetwork(String name) async {
  final path = await pathForXelisNetworkFile(name);
  final file = File(path);

  if (!await file.exists()) {
    throw FileSystemException('Missing Xelis network file', path);
  }

  final contents = await file.readAsString();
  return NetworkName.fromName(contents.trim());
}
