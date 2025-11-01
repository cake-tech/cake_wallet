import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/.secrets.g.dart' as secrets;
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/lightning/lightning_wallet.dart';
import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_bitcoin/psbt/v0_finalizer.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/parse_fixed.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/zpub.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:mobx/mobx.dart';
import 'package:ur/cbor_lite.dart';
import 'package:ur/ur.dart';
import 'package:ur/ur_decoder.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends ElectrumWallet with Store {
  BitcoinWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Box<PayjoinSession> payjoinBox,
    required EncryptionFileUtils encryptionFileUtils,
    Uint8List? seedBytes,
    String? mnemonic,
    String? xpub,
    String? addressPageType,
    BasedUtxoNetwork? networkParam,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    String? passphrase,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    bool? alwaysScan,
  }) : super(
          mnemonic: mnemonic,
          passphrase: passphrase,
          xpub: xpub,
          password: password,
          walletInfo: walletInfo,
          derivationInfo: derivationInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          network: networkParam == null
              ? BitcoinNetwork.mainnet
              : networkParam == BitcoinNetwork.mainnet
                  ? BitcoinNetwork.mainnet
                  : BitcoinNetwork.testnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          encryptionFileUtils: encryptionFileUtils,
          currency:
              networkParam == BitcoinNetwork.testnet ? CryptoCurrency.tbtc : CryptoCurrency.btc,
          alwaysScan: alwaysScan,
        ) {
    // in a standard BIP44 wallet, mainHd derivation path = m/84'/0'/0'/0 (account 0, index unspecified here)
    // the sideHd derivation path = m/84'/0'/0'/1 (account 1, index unspecified here)
    // String derivationPath = walletInfo.derivationInfo!.derivationPath!;
    // String sideDerivationPath = derivationPath.substring(0, derivationPath.length - 1) + "1";
    // final hd = bitcoin.HDWallet.fromSeed(seedBytes, network: networkType);

    if (mnemonic != null) {
      lightningWallet = LightningWallet(
        mnemonic: mnemonic,
        apiKey: secrets.breezApiKey,
        lnurlDomain: "breez.tips",
      );
    }

    payjoinManager = PayjoinManager(PayjoinStorage(payjoinBox), this);
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      mainHd: hd,
      sideHd: accountHD.childKey(Bip32KeyIndex(1)),
      network: networkParam ?? network,
      masterHd: seedBytes != null ? Bip32Slip10Secp256k1.fromSeed(seedBytes) : null,
      isHardwareWallet: walletInfo.isHardwareWallet,
      payjoinManager: payjoinManager,
      lightningWallet: lightningWallet,
    );


    if (lightningWallet != null) {
      walletAddresses.setLightningAddress(walletInfo.name);
    }
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  @override
  bool get hasRescan => true;

  static Future<BitcoinWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Box<PayjoinSession> payjoinBox,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
    String? addressPageType,
    BasedUtxoNetwork? network,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    int initialSilentAddressIndex = 0,
  }) async {
    late Uint8List seedBytes;

    final derivationInfo = await walletInfo.getDerivationInfo();

    switch (derivationInfo.derivationType) {
      case DerivationType.bip39:
        seedBytes = await bip39.mnemonicToSeed(
          mnemonic,
          passphrase: passphrase ?? "",
        );
        break;
      case DerivationType.electrum:
      default:
        seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? "");
        break;
    }

    return BitcoinWallet(
      mnemonic: mnemonic,
      passphrase: passphrase ?? "",
      password: password,
      walletInfo: walletInfo,
      derivationInfo: derivationInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      initialBalance: initialBalance,
      encryptionFileUtils: encryptionFileUtils,
      seedBytes: seedBytes,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: addressPageType,
      networkParam: network,
      payjoinBox: payjoinBox,
    );
  }

  static Future<BitcoinWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Box<PayjoinSession> payjoinBox,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final network = walletInfo.network != null
        ? BasedUtxoNetwork.fromName(walletInfo.network!)
        : BitcoinNetwork.mainnet;

    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp = null;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        network,
      );
    } catch (e) {
      if (!hasKeysFile) rethrow;
    }

    final WalletKeysData keysData;
    // Migrate wallet from the old scheme to then new .keys file scheme
    if (!hasKeysFile) {
      keysData = WalletKeysData(
        mnemonic: snp!.mnemonic,
        xPub: snp.xpub,
        passphrase: snp.passphrase,
      );
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    final derivationInfo = await walletInfo.getDerivationInfo();

    // set the default if not present:
    derivationInfo.derivationPath ??= snp?.derivationPath ?? electrum_path;
    derivationInfo.derivationType ??= snp?.derivationType ?? DerivationType.electrum;
    await derivationInfo.save();

    Uint8List? seedBytes = null;
    final mnemonic = keysData.mnemonic;
    final passphrase = keysData.passphrase;

    if (mnemonic != null) {
      switch (derivationInfo.derivationType) {
        case DerivationType.electrum:
          seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? "");
          break;
        case DerivationType.bip39:
        default:
          seedBytes = await bip39.mnemonicToSeed(
            mnemonic,
            passphrase: passphrase ?? '',
          );
          break;
      }
    }

    return BitcoinWallet(
        mnemonic: mnemonic,
        xpub: keysData.xPub != null ? convertZpubToXpub(keysData.xPub!) : null,
        password: password,
        passphrase: passphrase,
        walletInfo: walletInfo,
        derivationInfo: derivationInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp?.addresses,
        initialSilentAddresses: snp?.silentAddresses,
        initialSilentAddressIndex: snp?.silentAddressIndex ?? 0,
        initialBalance: snp?.balance,
        encryptionFileUtils: encryptionFileUtils,
        seedBytes: seedBytes,
        initialRegularAddressIndex: snp?.regularAddressIndex,
        initialChangeAddressIndex: snp?.changeAddressIndex,
        addressPageType: snp?.addressPageType,
        networkParam: network,
        alwaysScan: snp?.alwaysScan,
        payjoinBox: payjoinBox);
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    payjoinManager.cleanupSessions();
    super.close(shouldCleanup: shouldCleanup);
  }

  @override
  Future<ElectrumBalance> fetchBalances() async {
    final balance = await super.fetchBalances();
    if (lightningWallet == null) {
      return balance;
    }

    final lBalance = await lightningWallet!.getBalance();

    return ElectrumBalance(confirmed: balance.confirmed, unconfirmed: balance.unconfirmed, frozen: balance.frozen, secondConfirmed: lBalance.toInt());
  }

  late final LightningWallet? lightningWallet;

  late final PayjoinManager payjoinManager;

  bool get isPayjoinAvailable => unspentCoinsInfo.values
      .where((element) => element.walletId == id && element.isSending && !element.isFrozen)
      .isNotEmpty;

  Future<PsbtV2> buildPsbt({
    required List<BitcoinBaseOutput> outputs,
    required List<OutputInfo> cwOutputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    required Uint8List masterFingerprint,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final psbtReadyInputs = <PSBTReadyUtxoWithAddress>[];
    for (final utxo in utxos) {
      final rawTx = await electrumClient.getTransactionHex(hash: utxo.utxo.txHash);
      final publicKeyAndDerivationPath = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      psbtReadyInputs.add(PSBTReadyUtxoWithAddress(
        utxo: utxo.utxo,
        rawTx: rawTx,
        ownerDetails: utxo.ownerDetails,
        ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
        ownerMasterFingerprint: masterFingerprint,
        ownerPublicKey: publicKeyAndDerivationPath.publicKey,
      ));
    }

    return PSBTTransactionBuild(
            inputs: psbtReadyInputs, outputs: outputs, enableRBF: enableRBF, cwOutputs: cwOutputs)
        .psbt;
  }

  @override
  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinBaseOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required List<OutputInfo> cwOutputs,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final masterFingerprint =
        await (hardwareWalletService as BitcoinHardwareWalletService).getMasterFingerprint();

    final psbt = await buildPsbt(
      outputs: outputs,
      fee: fee,
      network: network,
      utxos: utxos,
      cwOutputs: cwOutputs,
      publicKeys: publicKeys,
      masterFingerprint: masterFingerprint,
      memo: memo,
      enableRBF: enableRBF,
      inputOrdering: inputOrdering,
      outputOrdering: outputOrdering,
    );

    final psbtStr = base64Encode(psbt.serialize());
    final rawHex = await hardwareWalletService!.signTransaction(transaction: psbtStr);
    return BtcTransaction.fromRaw(BytesUtils.toHexString(rawHex));
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    credentials = credentials as BitcoinTransactionCredentials;

    if ((credentials.coinTypeToSpendFrom == UnspentCoinType.lightning && lightningWallet != null) ||
        (await lightningWallet?.isCompatible(credentials.outputs.first.address)) == true) {
      final amount = parseFixed(credentials.outputs.first.cryptoAmount?.isNotEmpty == true ? credentials.outputs.first.cryptoAmount! : "0", 9);

      return lightningWallet!.createTransaction(credentials.outputs.first.address,
          amount > BigInt.zero ? amount : null, credentials.priority);
    }

    final tx = (await super.createTransaction(credentials)) as PendingBitcoinTransaction;

    final payjoinUri = credentials.payjoinUri;
    if (payjoinUri == null && !tx.shouldCommitUR()) return tx;

    final transaction = await buildPsbt(
        utxos: tx.utxos,
        outputs: tx.outputs
            .map((e) => BitcoinOutput(
                  address: addressFromScript(e.scriptPubKey),
                  value: e.amount,
                  isSilentPayment: e.isSilentPayment,
                  isChange: e.isChange,
                ))
            .toList(),
        cwOutputs: credentials.outputs,
        fee: BigInt.from(tx.fee),
        network: network,
        memo: credentials.outputs.first.memo,
        outputOrdering: BitcoinOrdering.none,
        enableRBF: true,
        publicKeys: tx.publicKeys!,
        masterFingerprint: Uint8List.fromList([0, 0, 0, 0]));

    if (tx.shouldCommitUR()) {
      tx.unsignedPsbt = transaction.asPsbtV0();
      return tx;
    }

    final originalPsbt =
        await signPsbt(base64.encode(transaction.asPsbtV0()), getUtxoWithPrivateKeys());

    tx.commitOverride = () async {
      final sender =
          await payjoinManager.initSender(payjoinUri!, originalPsbt, int.parse(tx.feeRate));
      payjoinManager.spawnNewSender(
          sender: sender, pjUrl: payjoinUri, amount: BigInt.from(tx.amount));
    };

    return tx;
  }

  List<UtxoWithPrivateKey> getUtxoWithPrivateKeys() => unspentCoins
      .where((e) => (e.isSending && !e.isFrozen))
      .map((unspent) => UtxoWithPrivateKey.fromUnspent(unspent, this))
      .toList();

  Future<void> commitPsbt(String finalizedPsbt) {
    final psbt = PsbtV2()..deserializeV0(base64.decode(finalizedPsbt));

    final btcTx = BtcTransaction.fromRaw(BytesUtils.toHexString(psbt.extract()));

    return PendingBitcoinTransaction(
      btcTx,
      type,
      electrumClient: electrumClient,
      amount: 0,
      fee: 0,
      feeRate: "",
      network: network,
      hasChange: true,
      isViewOnly: false,
    ).commit();
  }

  Future<String> signPsbt(String preProcessedPsbt, List<UtxoWithPrivateKey> utxos) async {
    final psbt = PsbtV2()..deserializeV0(base64Decode(preProcessedPsbt));

    await psbt.signWithUTXO(utxos, (txDigest, utxo, key, sighash) {
      return utxo.utxo.isP2tr()
          ? key.signTapRoot(
              txDigest,
              sighash: sighash,
              tweak: utxo.utxo.isSilentPayment != true,
            )
          : key.signInput(txDigest, sigHash: sighash);
    }, (txId, vout) async {
      final txHex = await electrumClient.getTransactionHex(hash: txId);
      final output = BtcTransaction.fromRaw(txHex).outputs[vout];
      return TaprootAmountScriptPair(output.amount, output.scriptPubKey);
    });

    psbt.finalizeV0();
    return base64Encode(psbt.asPsbtV0());
  }

  Future<void> commitPsbtUR(List<String> urCodes) async {
    if (urCodes.isEmpty) throw Exception("No QR code got scanned");
    bool isUr = urCodes.any((str) {
      return str.startsWith("ur:psbt/");
    });
    if (isUr) {
      final ur = URDecoder();
      for (final inp in urCodes) {
        ur.receivePart(inp);
      }
      final result = (ur.result as UR);
      final cbor = result.cbor;
      final cborDecoder = CBORDecoder(cbor);
      final out = cborDecoder.decodeBytes();
      final bytes = out.$1;
      final base64psbt = base64Encode(bytes);
      final psbt = PsbtV2()..deserializeV0(base64Decode(base64psbt));

      // psbt.finalize();
      final finalized = base64Encode(psbt.serialize());
      await commitPsbt(finalized);
    } else {
      final btcTx = BtcTransaction.fromRaw(urCodes.first);

      return PendingBitcoinTransaction(
        btcTx,
        type,
        electrumClient: electrumClient,
        amount: 0,
        fee: 0,
        feeRate: "",
        network: network,
        hasChange: true,
        isViewOnly: false,
      ).commit();
    }
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    if (walletInfo.isHardwareWallet) {
      final addressEntry = address != null
          ? walletAddresses.allAddresses.firstWhere((element) => element.address == address)
          : null;
      final index = addressEntry?.index ?? 0;
      final isChange = addressEntry?.isHidden == true ? 1 : 0;
      final derivationInfo = await walletInfo.getDerivationInfo();
      final accountPath = derivationInfo.derivationPath;
      final derivationPath = accountPath != null ? "$accountPath/$isChange/$index" : null;

      final signature = await hardwareWalletService!
          .signMessage(message: ascii.encode(message), derivationPath: derivationPath);
      return base64Encode(signature);
    }

    return super.signMessage(message, address: address);
  }
}
