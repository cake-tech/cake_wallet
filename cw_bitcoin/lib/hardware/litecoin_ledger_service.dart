import 'dart:async';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_litecoin/ledger_litecoin.dart';

class LitecoinLedgerService extends HardwareWalletService with BitcoinHardwareWalletService,   LitecoinHardwareWalletService {
  LitecoinLedgerService(this.ledgerConnection)
      : litecoinLedgerApp = LitecoinLedgerApp(ledgerConnection);

  final LedgerConnection ledgerConnection;
  final LitecoinLedgerApp litecoinLedgerApp;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
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

  @override
  Future<String> signLitecoinTransaction({
    required List<BitcoinBaseOutput> outputs,
    required List<PSBTReadyUtxoWithAddress> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  }) {

    final readyInputs = <LedgerTransaction>[];
    for (final utxo in inputs) {
      final publicKeyAndDerivationPath = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      readyInputs.add(LedgerTransaction(
        rawTx: utxo.rawTx,
        outputIndex: utxo.utxo.vout,
        ownerPublicKey: Uint8List.fromList(hex.decode(publicKeyAndDerivationPath.publicKey)),
        ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
      ));
    }

    // Check if we have the key to one of the output addresses to hide change on the device
    String? changePath;
    for (final output in outputs) {
      final maybeChangePath = publicKeys[(output as BitcoinOutput).address.pubKeyHash()];
      if (maybeChangePath != null) changePath ??= maybeChangePath.derivationPath;
    }

    return litecoinLedgerApp.createTransaction(
        inputs: readyInputs,
        outputs: outputs
            .map((e) => TransactionOutput.fromBigInt((e as BitcoinOutput).value,
            Uint8List.fromList(e.address.toScriptPubKey().toBytes())))
            .toList(),
        changePath: changePath,
        sigHashType: 0x01,
        additionals: ["bech32"],
        isSegWit: true,
        useTrustedInputForSegwit: true);
  }
}
