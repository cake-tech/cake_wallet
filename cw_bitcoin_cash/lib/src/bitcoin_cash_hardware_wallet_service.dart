import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/ledger_litecoin.dart';

class BitcoinCashHardwareWalletService {
  BitcoinCashHardwareWalletService(this.ledgerConnection);

  final LedgerConnection ledgerConnection;

  Future<List<HardwareAccountData>> getAvailableAccounts(
      {int index = 0, int limit = 5}) async {
    final bitcoinCashLedgerApp = LitecoinLedgerApp(ledgerConnection);

    final version = await bitcoinCashLedgerApp.getVersion();
    print(version);

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);
    final xpubVersion = Bip44Conf.bitcoinCashMainNet.keyNetVer;

    for (final i in indexRange) {
      final derivationPath = "m/44'/145'/$i'";
      final xpub = await bitcoinCashLedgerApp.getXPubKey(
        accountsDerivationPath: derivationPath,
        xPubVersion: int.parse(hex.encode(xpubVersion.public), radix: 16),
        addressFormat: AddressFormat.cashaddr,
      );
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xpub, xpubVersion)
          .childKey(Bip32KeyIndex(0));

      final address = generateP2PKHAddress(
          hd: hd, index: 0, network: BitcoinCashNetwork.mainnet);

      accounts.add(HardwareAccountData(
        address: address,
        accountIndex: i,
        derivationPath: derivationPath,
        xpub: xpub,
      ));
    }

    return accounts;
  }
}
