import 'dart:convert';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/file.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';

class ElectrumWallletSnapshot {
  ElectrumWallletSnapshot({
    required this.mnemonic,
   });

  String mnemonic;

  static Future<ElectrumWallletSnapshot> load(String name, WalletType type, String password) async {
    final path = await pathForWallet(name: name, type: type);
    final jsonSource = await read(path: path, password: password);
    // final data = json.decode(jsonSource) as Map;
    // final mnemonic = data['mnemonic'] as String;
    
    return ElectrumWallletSnapshot(
      mnemonic: jsonSource,
    );
  }
}