import "dart:async";
import "dart:typed_data";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart";
import "package:cw_bitcoin/psbt/transaction_builder.dart";
import "package:cw_bitcoin/utils.dart";
import "package:cw_bitcoin_cash/src/hardware/bitcoin_cash_hardware_wallet_service.dart";
import "package:cw_core/hardware/hardware_account_data.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart";
import "package:ledger_litecoin/ledger_litecoin.dart";

class BitcoinCashLedgerService extends HardwareWalletService
    with BitcoinHardwareWalletService, BitcoinCashHardwareWalletService {
  BitcoinCashLedgerService(this.ledgerConnection)
      : bitcoinCashLedgerApp = LitecoinLedgerApp(ledgerConnection);

  final LedgerConnection ledgerConnection;
  final LitecoinLedgerApp bitcoinCashLedgerApp;

  @override
  Future<List<HardwareAccountData>> getAvailableAccounts({int index = 0, int limit = 5}) async {
    await bitcoinCashLedgerApp.getVersion();

    final accounts = <HardwareAccountData>[];
    final indexRange = List.generate(limit, (i) => i + index);

    for (final i in indexRange) {
      final derivationPath = "m/44'/145'/$i'";
      final xpub = await bitcoinCashLedgerApp.getXPubKey(
        accountsDerivationPath: derivationPath,
        addressFormat: AddressFormat.cashaddr,
      );
      final hd = Bip32Slip10Secp256k1.fromExtendedKey(xpub).childKey(Bip32KeyIndex(0));

      final address = generateP2PKHAddress(hd: hd, index: 0, network: BitcoinCashNetwork.mainnet);

      accounts.add(
        HardwareAccountData(
          address: address,
          accountIndex: i,
          derivationPath: derivationPath,
          xpub: xpub,
        ),
      );
    }

    return accounts;
  }

  @override
  Future<String> signBitcoinCashTransaction({
    required List<PSBTReadyBitcoinOutput> outputs,
    required List<PSBTReadyUtxoWithAddress> inputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
  }) {
    final readyInputs = <LedgerTransaction>[];
    for (final utxo in inputs) {
      final publicKeyAndDerivationPath = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      readyInputs.add(
        LedgerTransaction(
          rawTx: utxo.rawTx,
          outputIndex: utxo.utxo.vout,
          ownerPublicKey: Uint8List.fromList(hex.decode(publicKeyAndDerivationPath.publicKey)),
          ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
        ),
      );
    }
    String? changePath;
    for (final output in outputs) {
      if (output.isChange) {
        changePath ??= output.changeDerivationPath;
      }
    }

    return bitcoinCashLedgerApp.createTransaction(
      inputs: readyInputs,
      outputs: outputs
          .map(
            (e) => TransactionOutput.fromBigInt(
              (e as BitcoinOutput).value,
              Uint8List.fromList(e.address.toScriptPubKey().toBytes()),
            ),
          )
          .toList(),
      changePath: changePath,
      sigHashType: 0x41,
      additionals: ["bip143", "cashaddr"],
    );
  }
}
