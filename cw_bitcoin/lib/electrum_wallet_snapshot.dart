import 'dart:convert';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_type.dart';

class ElectrumWalletSnapshot {
  ElectrumWalletSnapshot({
    required this.name,
    required this.type,
    required this.password,
    required this.mnemonic,
    required this.addresses,
    required this.balance,
    required this.regularAddressIndex,
    required this.changeAddressIndex,
    required this.addressPageType,
    required this.network,
  });

  final String name;
  final String password;
  final WalletType type;
  final String addressPageType;
  final BasedUtxoNetwork network;

  String mnemonic;
  List<BitcoinAddressRecord> addresses;
  ElectrumBalance balance;
  Map<String, int> regularAddressIndex;
  Map<String, int> changeAddressIndex;

  static Future<ElectrumWalletSnapshot> load(String name, WalletType type, String password, BasedUtxoNetwork? network) async {
    final path = await pathForWallet(name: name, type: type);
    final jsonSource = await read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;
    final addressesTmp = data['addresses'] as List? ?? <Object>[];
    final mnemonic = data['mnemonic'] as String;
    final addresses = addressesTmp
        .whereType<String>()
        .map((addr) => BitcoinAddressRecord.fromJSON(addr, network))
        .toList();
    final balance = ElectrumBalance.fromJSON(data['balance'] as String) ??
        ElectrumBalance(confirmed: 0, unconfirmed: 0, frozen: 0);
    var regularAddressIndexByType = {SegwitAddresType.p2wpkh.toString(): 0};
    var changeAddressIndexByType = {SegwitAddresType.p2wpkh.toString(): 0};

    try {
      regularAddressIndexByType = {
        SegwitAddresType.p2wpkh.toString(): int.parse(data['account_index'] as String? ?? '0')
      };
      changeAddressIndexByType = {
        SegwitAddresType.p2wpkh.toString():
            int.parse(data['change_address_index'] as String? ?? '0')
      };
    } catch (_) {
      try {
        regularAddressIndexByType = data["account_index"] as Map<String, int>? ?? {};
        changeAddressIndexByType = data["change_address_index"] as Map<String, int>? ?? {};
      } catch (_) {}
    }

    return ElectrumWalletSnapshot(
      name: name,
      type: type,
      password: password,
      mnemonic: mnemonic,
      addresses: addresses,
      balance: balance,
      regularAddressIndex: regularAddressIndexByType,
      changeAddressIndex: changeAddressIndexByType,
      addressPageType: data['address_page_type'] as String? ?? SegwitAddresType.p2wpkh.toString(),
      network: data['network_type'] == 'testnet' ? BitcoinNetwork.testnet : BitcoinNetwork.mainnet,
    );
  }
}
