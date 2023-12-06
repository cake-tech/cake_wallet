import 'dart:convert';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/file.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;

class ElectrumWalletSnapshot {
  ElectrumWalletSnapshot({
    required this.name,
    required this.type,
    required this.password,
    required this.mnemonic,
    required this.addresses,
    required this.silentAddresses,
    required this.balance,
    required this.networkType,
    required this.regularAddressIndex,
    required this.changeAddressIndex,
    required this.silentAddressIndex,
  });

  final String name;
  final String password;
  final WalletType type;

  String mnemonic;
  List<BitcoinAddressRecord> addresses;
  List<BitcoinAddressRecord> silentAddresses;
  ElectrumBalance balance;
  bitcoin.NetworkType networkType;
  int regularAddressIndex;
  int changeAddressIndex;
  int silentAddressIndex;

  static Future<ElectrumWalletSnapshot> load(String name, WalletType type, String password) async {
    final path = await pathForWallet(name: name, type: type);
    final jsonSource = await read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;
    final mnemonic = data['mnemonic'] as String;

    final addressesTmp = data['addresses'] as List? ?? <Object>[];
    final addresses = addressesTmp
        .whereType<String>()
        .map((addr) => BitcoinAddressRecord.fromJSON(addr))
        .toList();

    final silentAddressesTmp = data['silent_addresses'] as List? ?? <Object>[];
    final silentAddresses = silentAddressesTmp
        .whereType<String>()
        .map((addr) => BitcoinAddressRecord.fromJSON(addr))
        .toList();

    final balance = ElectrumBalance.fromJSON(data['balance'] as String) ??
        ElectrumBalance(confirmed: 0, unconfirmed: 0, frozen: 0);
    final networkType = data['network_type'] == 'testnet' ? bitcoin.testnet : bitcoin.bitcoin;

    var regularAddressIndex = 0;
    var changeAddressIndex = 0;
    var silentAddressIndex = 0;

    try {
      regularAddressIndex = int.parse(data['account_index'] as String? ?? '0');
      changeAddressIndex = int.parse(data['change_address_index'] as String? ?? '0');
      silentAddressIndex = int.parse(data['silent_address_index'] as String? ?? '0');
    } catch (_) {}

    return ElectrumWalletSnapshot(
      name: name,
      type: type,
      password: password,
      mnemonic: mnemonic,
      addresses: addresses,
      silentAddresses: silentAddresses,
      balance: balance,
      networkType: networkType,
      regularAddressIndex: regularAddressIndex,
      changeAddressIndex: changeAddressIndex,
      silentAddressIndex: silentAddressIndex,
    );
  }
}
