import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

class BitcoinLedgerService extends HardwareWalletService with BitcoinHardwareWalletService {
  BitcoinLedgerService(this.ledgerConnection)
      : bitcoinLedgerApp = BitcoinLedgerApp(ledgerConnection);

  final LedgerConnection ledgerConnection;
  final BitcoinLedgerApp bitcoinLedgerApp;

  void setAccountDerivationPath(String derivationPath) {
    bitcoinLedgerApp.derivationPath = derivationPath;
  }

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final masterFp = await bitcoinLedgerApp.getMasterFingerprint();

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/84'/0'/$i'";
      final xPub = await bitcoinLedgerApp.getXPubKey(derivationPath: derivationPath);
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xPub).childKey(Bip32KeyIndex(0));

      final address = generateP2WPKHAddress(hd: hd, index: 0, network: BitcoinNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        masterFingerprint: masterFp,
        xpub: xPub,
      ));
    }

    return accounts;
  }

  @override
  Future<Uint8List> signTransaction({required String transaction}) =>
      bitcoinLedgerApp.signPsbt(psbt: PsbtV2()..deserialize(base64Decode(transaction)));

  @override
  Future<Uint8List> getMasterFingerprint() => bitcoinLedgerApp.getMasterFingerprint();

  @override
  Future<Uint8List> signMessage({required Uint8List message, String? derivationPath}) =>
      bitcoinLedgerApp.signMessage(message: message, signDerivationPath: derivationPath);
}
