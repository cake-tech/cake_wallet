import 'dart:convert';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/file.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';

class ElectrumWallletSnapshot {
  ElectrumWallletSnapshot(this.name, this.type, this.password);

  final String name;
  final String password;
  final WalletType type;

  String mnemonic;
  List<BitcoinAddressRecord> addresses;
  ElectrumBalance balance;
  int regularAddressIndex;
  int changeAddressIndex;

  Future<void> load() async {
    try {
      final path = await pathForWallet(name: name, type: type);
      final jsonSource = await read(path: path, password: password);
      final data = json.decode(jsonSource) as Map;
      final addressesTmp = data['addresses'] as List ?? <Object>[];
      mnemonic = data['mnemonic'] as String;
      addresses = addressesTmp
          .whereType<String>()
          .map((addr) => BitcoinAddressRecord.fromJSON(addr))
          .toList();
      balance = ElectrumBalance.fromJSON(data['balance'] as String) ??
          ElectrumBalance(confirmed: 0, unconfirmed: 0);
      regularAddressIndex = 0;
      changeAddressIndex = 0;

      try {
        regularAddressIndex = int.parse(data['account_index'] as String);
        changeAddressIndex = int.parse(data['change_address_index'] as String);
      } catch (_) {}
    } catch (e) {
      print(e);
    }
  }
}
