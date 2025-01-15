import 'dart:convert';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/wallet_type.dart';

class BitcoinWalletSnapshot extends ElectrumWalletSnapshot {
  BitcoinWalletSnapshot({
    required super.name,
    required super.type,
    required super.password,
    required super.mnemonic,
    required super.xpub,
    required super.addresses,
    required super.balance,
    required super.regularAddressIndex,
    required super.changeAddressIndex,
    required super.addressPageType,
    required this.silentAddressIndex,
    required this.silentAddresses,
    required this.alwaysScan,
    required super.unspentCoins,
    super.passphrase,
    super.derivationType,
    super.derivationPath,
  }) : super();

  List<BitcoinSilentPaymentAddressRecord> silentAddresses;
  bool alwaysScan;
  int silentAddressIndex;

  static Future<BitcoinWalletSnapshot> load(
    EncryptionFileUtils encryptionFileUtils,
    String name,
    WalletType type,
    String password,
    BasedUtxoNetwork network,
  ) async {
    final path = await pathForWallet(name: name, type: type);
    final jsonSource = await encryptionFileUtils.read(path: path, password: password);
    final data = json.decode(jsonSource) as Map;

    final ElectrumWalletSnapshot electrumWalletSnapshot = await ElectrumWalletSnapshot.load(
      encryptionFileUtils,
      name,
      type,
      password,
      network,
    );

    final silentAddressesTmp = data['silent_addresses'] as List? ?? <Object>[];
    final silentAddresses = silentAddressesTmp.whereType<String>().map((j) {
      final decoded = json.decode(jsonSource) as Map;
      if (decoded['tweak'] != null || decoded['silent_payment_tweak'] != null) {
        return BitcoinReceivedSPAddressRecord.fromJSON(j);
      } else {
        return BitcoinSilentPaymentAddressRecord.fromJSON(j);
      }
    }).toList();
    final alwaysScan = data['alwaysScan'] as bool? ?? false;
    var silentAddressIndex = 0;

    try {
      silentAddressIndex = int.parse(data['silent_address_index'] as String? ?? '0');
    } catch (_) {}

    return BitcoinWalletSnapshot(
      name: name,
      type: type,
      password: password,
      passphrase: electrumWalletSnapshot.passphrase,
      mnemonic: electrumWalletSnapshot.mnemonic,
      xpub: electrumWalletSnapshot.xpub,
      addresses: electrumWalletSnapshot.addresses,
      regularAddressIndex: electrumWalletSnapshot.regularAddressIndex,
      balance: electrumWalletSnapshot.balance,
      changeAddressIndex: electrumWalletSnapshot.changeAddressIndex,
      addressPageType: electrumWalletSnapshot.addressPageType,
      derivationType: electrumWalletSnapshot.derivationType,
      derivationPath: electrumWalletSnapshot.derivationPath,
      unspentCoins: electrumWalletSnapshot.unspentCoins,
      silentAddressIndex: silentAddressIndex,
      silentAddresses: silentAddresses,
      alwaysScan: alwaysScan,
    );
  }
}
