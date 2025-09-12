import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/ledger_litecoin.dart';

class LitecoinLedgerService extends HardwareWalletService {
  LitecoinLedgerService(this.ledgerConnection);

  final LedgerConnection ledgerConnection;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    final litecoinLedgerApp = LitecoinLedgerApp(ledgerConnection);

    await litecoinLedgerApp.getVersion();

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);
    final xpubVersion = Bip44Conf.litecoinMainNet.altKeyNetVer;

    for (final i in indexRange) {
      final derivationPath = "m/84'/2'/$i'";
      final xpub = await litecoinLedgerApp.getXPubKey(
          accountsDerivationPath: derivationPath,
          xPubVersion: int.parse(hex.encode(xpubVersion.public), radix: 16));
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xpub, xpubVersion).childKey(Bip32KeyIndex(0));

      final address = generateP2WPKHAddress(hd: hd, index: 0, network: LitecoinNetwork.mainnet);

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
