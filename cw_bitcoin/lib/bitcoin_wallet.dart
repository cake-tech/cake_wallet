import 'dart:async';
import 'dart:convert';

import 'package:cw_core/utils/bip39_seed.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:collection/collection.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart'
    show
        CpfpInput,
        PrepareRecoverFundsResponse,
        RecoverFundsResponse,
        RecoveryMethod,
        RecoveryVerdict_Done,
        RecoveryVerdict_Redo,
        RecoveryVerdict_Valid,
        SdkError_InsufficientCpfpFunds,
        SkippedLeafReason_FeeExceedsValue,
        SkippedLeafReason_FundsNotFound,
        SkippedLeafReason_NotRecoverable,
        SkippedLeafReason_OperatorsUnavailable,
        SkippedLeafReason_Unverified;
import 'package:cw_bitcoin/.secrets.g.dart' as secrets;
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import "package:cw_bitcoin/bitcoin_receive_page_option.dart";
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/unknown_derivation.dart';
import 'package:cw_bitcoin/locktime.dart';
import 'package:cw_bitcoin/hardware/bitcoin_hardware_wallet_service.dart';
import 'package:cw_bitcoin/lightning/lightning_wallet.dart';
import 'package:cw_bitcoin/lightning/pending_lightning_transaction.dart';
import 'package:cw_bitcoin/lightning/unilateral_exit.dart';
import 'package:cw_bitcoin/lightning/unilateral_exit_plan_store.dart';
import 'package:cw_bitcoin/hardware/bitcoin_ledger_service.dart';
import 'package:cw_bitcoin/output_ordering.dart';
import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/payjoin/storage.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/psbt/signer.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:cw_bitcoin/psbt/v0_deserialize.dart';
import 'package:cw_bitcoin/psbt/v0_finalizer.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import "package:cw_core/exceptions.dart"
    show
        UnilateralExitBlock,
        UnilateralExitBlockedException,
        UnilateralExitFeeExceedsRecoveryException,
        UnilateralExitFundingShortfallException,
        UnilateralExitNoLeavesException;
import "package:cw_core/exceptions/cake_exception.dart";
import 'package:cw_core/output_info.dart';
import 'package:cw_core/payjoin_session.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import "package:cw_core/receive_page_option.dart";
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/print_verbose.dart';
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
    ElectrumBalance? initialLightningBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    String? passphrase,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    bool? alwaysScan,
    bool? useLightning,
    String? cachedLightningAddress,
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
          useLightning: useLightning ?? true,
        ) {
    // in a standard BIP44 wallet, mainHd derivation path = m/84'/0'/0'/0 (account 0, index unspecified here)
    // the sideHd derivation path = m/84'/0'/0'/1 (account 1, index unspecified here)
    // String derivationPath = walletInfo.derivationInfo!.derivationPath!;
    // String sideDerivationPath = derivationPath.substring(0, derivationPath.length - 1) + "1";
    // final hd = bitcoin.HDWallet.fromSeed(seedBytes, network: networkType);

    if (mnemonic != null && this.useLightning && LightningWallet.isAvailable) {
      try {
        lightningWallet = LightningWallet(
          mnemonic: mnemonic,
          passphrase: passphrase,
          seedBytes: seedBytes,
          apiKey: secrets.breezApiKey,
          lnurlDomain: "cake.cash",
          cachedAddress: cachedLightningAddress,
        );
      } catch (e) {
        printV(e);
      }
    }

    payjoinManager = PayjoinManager(PayjoinStorage(payjoinBox), this);
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      mainHdByTypeAndAccount: mainHdByTypeAndAccount,
      sideHdByTypeAndAccount: sideHdByTypeAndAccount,
      accountIndexes: [currentAccountIndex],
      currentAccountIndex: currentAccountIndex,
      legacyMainHd: mainHd,
      legacySideHd: sideHd,
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

    reaction((_) => this.useLightning, (bool useLightning) {
      if (useLightning && LightningWallet.isAvailable) {
        if (mnemonic != null) {
          lightningWallet = LightningWallet(
            mnemonic: mnemonic,
            passphrase: passphrase,
            seedBytes: seedBytes,
            apiKey: secrets.breezApiKey,
            lnurlDomain: "cake.cash",
            cachedAddress: cachedLightningAddress,
          );
          walletAddresses.lightningWallet = lightningWallet;
          walletAddresses.setLightningAddress(walletInfo.name);
        }
      } else {
        lightningWallet?.close();
        lightningWallet = null;
      }
    });

    if (initialLightningBalance != null) {
      balance[CryptoCurrency.btcln] = initialLightningBalance;
    }
  }

  bool get isLightningInitialized => lightningWallet?.isInitialized == true;

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
        seedBytes = bip39MnemonicToSeed(mnemonic, passphrase: passphrase ?? "");
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
      useLightning: true,
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
    derivationInfo.derivationType ??= snp?.derivationType ?? DerivationType.electrum;
    if (derivationInfo.derivationType == DerivationType.unknown) {
      resolveUnknownDerivation(
        derivationInfo,
        walletType: walletInfo.type,
        mnemonic: keysData.mnemonic,
        snapshotPath: snp?.derivationPath,
        snapshotType: snp?.derivationType,
      );
    } else {
      derivationInfo.derivationPath ??= snp?.derivationPath ?? electrum_path;
    }
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
          seedBytes = bip39MnemonicToSeed(mnemonic, passphrase: passphrase ?? '');
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
      initialLightningBalance: snp?.lightningBalance,
      encryptionFileUtils: encryptionFileUtils,
      seedBytes: seedBytes,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: snp?.addressPageType,
      networkParam: network,
      alwaysScan: snp?.alwaysScan,
      useLightning: snp?.useLightning,
      cachedLightningAddress: snp?.cachedLightningAddress,
      payjoinBox: payjoinBox,
    );
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    payjoinManager.cleanupSessions();
    await lightningWallet?.close();
    super.close(shouldCleanup: shouldCleanup);
  }

  @override
  Future<ElectrumBalance> fetchBalances() async {
    final balance = await super.fetchBalances();
    if (!isLightningInitialized || lightningWallet == null) {
      return balance;
    }

    await _refreshLightningBalance();

    return ElectrumBalance(
      confirmed: balance.confirmed,
      unconfirmed: balance.unconfirmed,
      frozen: balance.frozen ?? Money.zero(currency),
    );
  }

  Future<void> _refreshLightningBalance() async {
    try {
      final lBalance = await lightningWallet!.getBalance();

      balance[CryptoCurrency.btcln] = ElectrumBalance(
          confirmed: lBalance,
          unconfirmed: Money.zero(CryptoCurrency.btcln),
          frozen: Money.zero(CryptoCurrency.btcln));
    } catch (e) {
      printV("Error fetching lightning balance: $e");
    }
  }

  @override
  @action
  Future<void> subscribeForUpdates() async {
    if (isLightningInitialized && lightningWallet != null) {
      lightningWallet!.setEventListener(
        onTransactionEvent: (tx) async {
          if (transactionHistory.transactions[tx.id]?.isPending != tx.isPending) {
            transactionHistory.addOne(tx);
            await transactionHistory.save();
            await fetchBalances();
          }
        },
        onCreateDepositTransactionEvent: (txs) async {
          if (txs.isNotEmpty) {
            transactionHistory.addMany(txs);
            await transactionHistory.save();
          }
        },
        onUpdateDepositTransactionEvent: (txs) async {
          if (txs.isNotEmpty) {
            txs.forEach((tx) => transactionHistory.transactions.remove(tx.id));
            await transactionHistory.save();
          }
        },
        onBalanceChangedEvent: fetchBalances,
      );
    }

    return super.subscribeForUpdates();
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    if (lightningWallet != null) {
      final existingTx = transactionHistory.transactions.values
          .where((e) => (e.additionalInfo["isLightning"] as bool?) == true)
          .lastOrNull;

      lightningWallet!.getTransactionHistory(fromDate: existingTx?.date).then((lnHistory) async {
        transactionHistory.addMany(lnHistory);
        await transactionHistory.save();
      }).onError((_, __) {});
    }

    // Nothing else wakes up a unilateral exit later, so we check it on every sync.
    unawaited(advanceUnilateralExit());

    final transactions = await super.fetchTransactions();
    await _recordUnilateralExitHistory();

    return transactions;
  }

  LightningWallet? lightningWallet;

  late final PayjoinManager payjoinManager;

  @override
  bool get hasPayjoinSupport => keys.privateKey.isNotEmpty;

  @override
  bool get hasLightningSupport => seed != null && LightningWallet.isAvailable;

  bool get isPayjoinAvailable => unspentCoinsInfo.values
      .where((element) => element.walletId == id && element.isSending && !element.isFrozen)
      .isNotEmpty;

  Future<PsbtV2> buildPsbt({
    required List<BitcoinOutput> outputs,
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

      psbtReadyInputs.add(
        PSBTReadyUtxoWithAddress(
          utxo: utxo.utxo,
          rawTx: rawTx,
          ownerDetails: utxo.ownerDetails,
          ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
          ownerMasterFingerprint: masterFingerprint,
          ownerPublicKey: publicKeyAndDerivationPath.publicKey,
        ),
      );
    }

    final psbtReadyOutputs = outputs.map((o) {
      final cwOutput = cwOutputs
          .where(
            (e) => [e.address, e.extractedAddress]
                .map((e) => e?.toLowerCase())
                .contains(o.address.toAddress().toLowerCase()),
          )
          .firstOrNull;

      if (o.isChange && publicKeys.containsKey(o.address.pubKeyHash())) {
        final changeKey = publicKeys[o.address.pubKeyHash()]!;
        return PSBTReadyBitcoinOutput(
          address: o.address,
          value: o.value,
          isSilentPayment: o.isSilentPayment,
          isChange: o.isChange,
          changeMasterFingerprint: masterFingerprint,
          changeDerivationPath: changeKey.derivationPath,
          changePublicKey: changeKey.publicKey,
          outputInfo: cwOutput,
        );
      }
      return PSBTReadyBitcoinOutput(
        address: o.address,
        value: o.value,
        isSilentPayment: o.isSilentPayment,
        isChange: o.isChange,
        outputInfo: cwOutput,
      );
    }).toList();

    final locktime = antiFeeSnipingLocktime(
      chainTip: await getCurrentChainTip(),
      synced: syncStatus is SyncedSyncStatus,
    );

    return PSBTTransactionBuild(
      inputs: psbtReadyInputs,
      outputs: psbtReadyOutputs,
      enableRBF: enableRBF,
      locktime: locktime,
    ).psbt;
  }

  @override
  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinOutput> outputs,
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

    final orderedOutputs = orderOutputs(outputs, outputOrdering);

    final psbt = await buildPsbt(
      outputs: orderedOutputs,
      fee: fee,
      network: network,
      utxos: utxos,
      cwOutputs: cwOutputs,
      publicKeys: publicKeys,
      masterFingerprint: masterFingerprint,
      memo: memo,
      enableRBF: enableRBF,
      inputOrdering: inputOrdering,
      // Already applied above; don't reorder again.
      outputOrdering: BitcoinOrdering.none,
    );

    final psbtStr = base64Encode(psbt.serialize());
    if (hardwareWalletService is BitcoinLedgerService && derivationInfo.derivationPath != null) {
      (hardwareWalletService as BitcoinLedgerService)
          .setAccountDerivationPath(derivationInfo.derivationPath!);
    }

    final rawHex = await hardwareWalletService!.signTransaction(transaction: psbtStr);
    return BtcTransaction.fromRaw(BytesUtils.toHexString(rawHex));
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    credentials = credentials as BitcoinTransactionCredentials;
    final lnAddr = credentials.outputs.first.isParsedAddress
        ? credentials.outputs.first.extractedAddress!
        : credentials.outputs.first.address;

    final isLNCompatible = await lightningWallet?.isCompatible(lnAddr);
    if ((credentials.coinTypeToSpendFrom == UnspentCoinType.lightning && lightningWallet != null) ||
        isLNCompatible == true) {
      Money amount;
      if (credentials.outputs.first.sendAll) {
        amount = await lightningWallet!.getBalance();
      } else {
        amount = credentials.outputs.first.cryptoAmount;
      }

      return lightningWallet!.createTransaction(
        lnAddr,
        amount.amount > BigInt.zero ? amount.amount : null,
        credentials.priority,
        credentials.outputs.first.sendAll,
      );
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
        fee: tx.fee.amount,
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
      payjoinManager.spawnNewSender(sender: sender, pjUrl: payjoinUri, amount: tx.amount.amount);
    };

    return tx;
  }

  List<UtxoWithPrivateKey> getUtxoWithPrivateKeys({bool confirmedOnly = false}) =>
      unspentCoinsForCurrentAccount
          .where(
              (e) => e.isSending && !e.isFrozen && (!confirmedOnly || (e.confirmations ?? 0) > 0))
          .map((unspent) => UtxoWithPrivateKey.fromUnspent(unspent, this))
          .toList();

  Future<void> commitPsbt(String finalizedPsbt) {
    final psbt = PsbtV2()..deserializeV0(base64.decode(finalizedPsbt));

    final btcTx = BtcTransaction.fromRaw(BytesUtils.toHexString(psbt.extract()));

    return PendingBitcoinTransaction(
      btcTx,
      type,
      accountIndex: currentAccountIndex,
      electrumClient: electrumClient,
      amount: Money.zero(currency),
      fee: Money.zero(currency),
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

  bool _isAdvancingUnilateralExit = false;

  UnilateralExitPlanStore get _unilateralExitPlanStore =>
      UnilateralExitPlanStore(walletId: walletInfo.id);

  /// An unused P2WPKH receive address of the current account, where a
  /// unilateral exit sweeps the Spark funds.
  String get unilateralExitDestination {
    final destination = walletAddresses.allAddresses.firstWhereOrNull(
      (record) =>
          record.type == SegwitAddresType.p2wpkh &&
          record.accountIndex == currentAccountIndex &&
          !record.isHidden &&
          !record.isUsed,
    );

    if (destination == null) {
      throw UnilateralExitBlockedException(UnilateralExitBlock.noDestination);
    }

    return destination.address;
  }

  /// Merges the Spark balance into the fewest, largest leaves before an exit is quoted, so
  /// more of it is worth exiting.
  Future<void> mergeLeavesForUnilateralExit() async {
    if (lightningWallet == null || !isLightningInitialized) {
      throw UnilateralExitBlockedException(UnilateralExitBlock.lightningDisabled);
    }

    // Leaves already in an exit are not the wallet's to swap; a rebuild keeps them as they are.
    if (await _loadUnilateralExitPlan() != null) {
      return;
    }

    await lightningWallet!.consolidateLeavesForExit();
  }

  /// Quotes an exit at [feeRate] of [leafIds], or of every leaf worth exiting when null.
  /// While an exit is under way it quotes rebuilding that one instead: the same leaves at
  /// the new rate, keeping what already confirmed. That is how its fee is raised.
  Future<
      ({
        bool isRebuild,
        int recoverableSat,
        int feeSat,
        List<({String id, int valueSat, bool isCooperative})> leaves,
        List<({String id, int valueSat, String reason, String? message})> skipped,
      })> quoteUnilateralExit({
    required String destination,
    required int feeRate,
    List<String>? leafIds,
  }) async {
    final ongoing = await _loadUnilateralExitPlan();
    final quote = await _prepareUnilateralExit(
      ongoing: ongoing,
      destination: destination,
      feeRate: feeRate,
      leafIds: leafIds,
    );

    return (
      isRebuild: ongoing != null,
      recoverableSat: quote.recoverableValueSats.toInt(),
      feeSat: quote.totalFeeSats.toInt(),
      leaves: [
        for (final leaf in quote.leaves)
          (
            id: leaf.leafId,
            valueSat: leaf.valueSats.toInt(),
            isCooperative: leaf.method == RecoveryMethod.cooperative,
          ),
      ],
      skipped: [
        for (final leaf in quote.skipped)
          (
            id: leaf.leafId,
            valueSat: leaf.valueSats.toInt(),
            reason: switch (leaf.reason) {
              SkippedLeafReason_FeeExceedsValue() => "feeExceedsValue",
              SkippedLeafReason_FundsNotFound() => "fundsNotFound",
              SkippedLeafReason_Unverified() => "unverified",
              SkippedLeafReason_OperatorsUnavailable() => "operatorsUnavailable",
              SkippedLeafReason_NotRecoverable() => "notRecoverable",
            },
            message: switch (leaf.reason) {
              SkippedLeafReason_NotRecoverable(:final message) => message,
              _ => null,
            },
          ),
      ],
    );
  }

  Future<PrepareRecoverFundsResponse> _prepareUnilateralExit({
    required UnilateralExitPlan? ongoing,
    required String destination,
    required int feeRate,
    required List<String>? leafIds,
  }) {
    if (lightningWallet == null || !isLightningInitialized) {
      throw UnilateralExitBlockedException(UnilateralExitBlock.lightningDisabled);
    }

    return lightningWallet!.prepareUnilateralExit(
      feeRate: feeRate,
      destination: ongoing?.recovery.destination ?? destination,
      leafIds: ongoing?.leafIds ?? leafIds,
    );
  }

  /// A recovery must return more than it costs, fan-out fee included.
  void _requireWorthwhileUnilateralExit(PrepareRecoverFundsResponse quote, int feeRate) {
    if (quote.leaves.isEmpty) {
      throw UnilateralExitNoLeavesException(feeRate: feeRate);
    }

    if (quote.recoverableValueSats <= quote.totalFeeSats) {
      throw UnilateralExitFeeExceedsRecoveryException(
        feeRate: feeRate,
        feeSat: quote.totalFeeSats.toInt(),
        recoverableSat: quote.recoverableValueSats.toInt(),
      );
    }
  }

  /// Builds a signed exit of [leafIds] (every leaf worth it when null) to [destination],
  /// or rebuilds the exit under way at [feeRate]. Committing keeps the recovery and sends
  /// what is ready; later steps go out on sync as the SDK reports them ready.
  Future<PendingTransaction> createUnilateralExitTransaction({
    required String destination,
    required int feeRate,
    List<String>? leafIds,
  }) async {
    final ongoing = await _loadUnilateralExitPlan();
    final quote = await _prepareUnilateralExit(
      ongoing: ongoing,
      destination: destination,
      feeRate: feeRate,
      leafIds: leafIds,
    );
    _requireWorthwhileUnilateralExit(quote, feeRate);

    final response = await _buildUnilateralExit(quote, ongoing: ongoing, feeRate: feeRate);

    if (response.transactions.isEmpty) {
      throw UnilateralExitBlockedException(UnilateralExitBlock.noFundsLeft);
    }

    // A rebuild keeps the exit's id, so it replaces the record of the one it supersedes.
    final plan = ongoing == null
        ? UnilateralExitPlan.start(response, accountIndex: currentAccountIndex)
        : ongoing.copyWith(
            recovery: response,
            status: UnilateralExitStatus.active,
            inMempoolTxids: const {},
          );

    return PendingLightningTransaction(
      id: plan.steps.last.txid,
      amount: Money(response.recoverableValueSats, CryptoCurrency.btc),
      fee: Money(response.totalFeeSats, CryptoCurrency.btc),
      commitOverride: () async {
        await _saveUnilateralExit(plan);

        final progress =
            await UnilateralExitBroadcaster(electrumClient: electrumClient).broadcastReady(plan);

        // A new exit that got nothing out is dropped rather than retried on every sync.
        if (ongoing == null && progress.broadcastCount == 0 && progress.broadcastError != null) {
          await _unilateralExitPlanStore.delete(plan.id);
          throw TransactionSendingException(progress.broadcastError!);
        }

        final sent = plan.copyWith(
          status: progress.isStalled ? UnilateralExitStatus.stalled : UnilateralExitStatus.active,
          inMempoolTxids: progress.inMempoolTxids,
        );

        await _saveUnilateralExit(sent);
        await _setUnilateralExitCoinsFrozen(sent, isFrozen: true);
        await _recordUnilateralExitHistory();
        await _refreshLightningBalance();

        return plan.steps.last.txid;
      },
    );
  }

  /// A new exit is funded from fresh coins. A rebuild passes back the coins the exit
  /// already funded, which the SDK follows to their change, and adds fresh ones only when
  /// that is not enough.
  Future<RecoverFundsResponse> _buildUnilateralExit(
    PrepareRecoverFundsResponse quote, {
    required UnilateralExitPlan? ongoing,
    required int feeRate,
  }) async {
    final previousInputs = ongoing?.recovery.fundingInputs ?? const <CpfpInput>[];
    // Leaves the operators already moved on-chain recover cooperatively, with no funding.
    final requiredSat = quote.funding?.singleUtxoSats ?? BigInt.zero;
    final freshCoins = previousInputs.isEmpty && requiredSat > BigInt.zero
        ? _selectUnilateralExitFunding(requiredSat, feeRate)
        : <UtxoWithPrivateKey>[];

    Future<RecoverFundsResponse> build(List<UtxoWithPrivateKey> coins) =>
        lightningWallet!.unilateralExitWithSigner(
          quote: quote,
          fundingInputs: [...previousInputs, ...coins.map(_cpfpInputOf)],
          signPsbt: _signUnilateralExitPsbt,
        );

    try {
      return await build(freshCoins);
    } on SdkError_InsufficientCpfpFunds catch (e) {
      if (previousInputs.isEmpty) {
        rethrow;
      }

      return build(_selectUnilateralExitFunding(e.requiredSats, feeRate));
    }
  }

  CpfpInput _cpfpInputOf(UtxoWithPrivateKey coin) => CpfpInput.p2Wpkh(
        txid: coin.utxo.txHash,
        vout: coin.utxo.vout,
        valueSats: coin.utxo.value,
        pubkey: coin.privateKey.getPublic().toHex(),
      );

  /// Largest coins first, until they cover the quote plus the extra input
  /// weight every coin after the first adds.
  List<UtxoWithPrivateKey> _selectUnilateralExitFunding(BigInt requiredSat, int feeRate) {
    const p2wpkhInputVbytes = 68;

    final candidates = getUtxoWithPrivateKeys(confirmedOnly: true)
        .where((input) => input.utxo.scriptType == SegwitAddresType.p2wpkh)
        .toList()
      ..sort((a, b) => b.utxo.value.compareTo(a.utxo.value));

    final selected = <UtxoWithPrivateKey>[];
    var total = BigInt.zero;

    for (final input in candidates) {
      final needed = requiredSat + BigInt.from(selected.length * p2wpkhInputVbytes * feeRate);

      if (total >= needed) {
        break;
      }

      selected.add(input);
      total += input.utxo.value;
    }

    final needed = requiredSat + BigInt.from((selected.length - 1) * p2wpkhInputVbytes * feeRate);

    if (selected.isEmpty || total < needed) {
      throw UnilateralExitFundingShortfallException(neededSat: needed.toInt());
    }

    return selected;
  }

  /// Signs every unfinalized input paying to one of this account's P2WPKH coins: the
  /// funding coins, and on a rebuild the CPFP change the exit sent back to them, which is
  /// frozen and so not among the spendable coins.
  Future<Uint8List> _signUnilateralExitPsbt(Uint8List psbtBytes) async {
    final psbt = PsbtV2()..deserializeV0(psbtBytes);
    final keysByScript = {
      for (final coin in unspentCoinsForCurrentAccount
          .where((coin) => coin.bitcoinAddressRecord.type == SegwitAddresType.p2wpkh))
        BytesUtils.toHexString(
          UtxoWithPrivateKey.fromUnspent(coin, this)
              .privateKey
              .getPublic()
              .toP2wpkhAddress()
              .toScriptPubKey()
              .toBytes(),
        ): UtxoWithPrivateKey.fromUnspent(coin, this),
    };

    final inputsToSign = <UtxoWithPrivateKey>[];

    for (var i = 0; i < psbt.getGlobalInputCount(); i++) {
      if (psbt.getInputFinalScriptsig(i) != null) {
        continue;
      }

      try {
        psbt.getInputFinalScriptwitness(i);
        continue;
      } catch (_) {} // Not finalized yet

      final witnessUtxo = psbt.getInputWitnessUtxo(i);
      if (witnessUtxo == null) {
        continue;
      }

      final (amount, script) = witnessUtxo;
      final owner = keysByScript[BytesUtils.toHexString(script)];
      if (owner == null) {
        continue;
      }

      inputsToSign.add(
        UtxoWithPrivateKey(
          utxo: BitcoinUtxo(
            // PSBT stores the previous txid in internal (reversed) byte order.
            txHash: BytesUtils.toHexString(psbt.getInputPreviousTxid(i).reversed.toList()),
            value: BigintUtils.fromBytes(amount, byteOrder: Endian.little),
            vout: psbt.getInputOutputIndex(i),
            scriptType: SegwitAddresType.p2wpkh,
          ),
          ownerDetails: owner.ownerDetails,
          privateKey: owner.privateKey,
        ),
      );
    }

    await psbt.signWithUTXO(
      inputsToSign,
      (digest, utxo, key, sighash) => key.signInput(digest, sigHash: sighash),
    );
    psbt.finalizeV0();

    return psbt.asPsbtV0();
  }

  /// Every exit this wallet has made, oldest first.
  Future<List<UnilateralExitPlan>> _loadUnilateralExits() async {
    final exits = <UnilateralExitPlan>[];

    for (final json in await _unilateralExitPlanStore.readAll()) {
      // One unreadable row must not stop the wallet from syncing.
      try {
        exits.add(UnilateralExitPlan.fromJson(json));
      } catch (e) {
        printV("unilateral exit: skipping unreadable record: $e");
      }
    }

    exits.sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs));

    return exits;
  }

  /// The exit still under way, if any. A wallet runs one exit at a time.
  Future<UnilateralExitPlan?> _loadUnilateralExitPlan() async =>
      (await _loadUnilateralExits()).where((exit) => exit.isOngoing).firstOrNull;

  /// Puts every step of every exit in the history, titled by what it does. A step that is
  /// already a wallet transaction (a fee payment, the fan-out, the sweep) keeps its amounts
  /// and only gains the tags; the other steps get rows of their own.
  Future<void> _recordUnilateralExitHistory() async {
    final exits = await _loadUnilateralExits();
    if (exits.isEmpty) {
      return;
    }

    for (final exit in exits) {
      for (final (index, entry) in exit.historyEntries.indexed) {
        final existing = transactionHistory.transactions[entry.txid];

        if (existing != null) {
          existing.additionalInfo = {...existing.additionalInfo, ...entry.additionalInfo};
          transactionHistory.addOne(existing);
          continue;
        }

        // A fee payment only exists as a wallet transaction once it is broadcast.
        if (entry.kind == UnilateralExitHistoryKind.fee) {
          continue;
        }

        final isConfirmed = entry.state == UnilateralExitStepState.confirmed;

        transactionHistory.addOne(ElectrumTransactionInfo(
          WalletType.bitcoin,
          id: entry.txid,
          amount: Money(BigInt.from(entry.amountSat), currency),
          fee: Money.zero(currency),
          direction: TransactionDirection.incoming,
          isPending: !isConfirmed,
          // Keeps the steps in order in the history.
          date: DateTime.fromMillisecondsSinceEpoch(exit.startedAtMs + index),
          confirmations: isConfirmed ? 1 : 0,
          accountIndex: exit.accountIndex,
          additionalInfo: entry.additionalInfo,
        ));
      }
    }

    await transactionHistory.save();
  }

  Future<void> _saveUnilateralExit(UnilateralExitPlan exit) =>
      _unilateralExitPlanStore.write(exit.id, exit.toJson());

  /// Follows the exit under way with the SDK's check: completes it when everything has
  /// confirmed, marks it for a rebuild when the chain no longer matches it, and otherwise
  /// sends whatever is ready.
  Future<void> advanceUnilateralExit() async {
    if (_isAdvancingUnilateralExit || lightningWallet == null || !isLightningInitialized) {
      return;
    }

    _isAdvancingUnilateralExit = true;
    try {
      final exit = await _loadUnilateralExitPlan();

      // An exit that needs rebuilding waits for the user to build it again.
      if (exit == null || exit.status == UnilateralExitStatus.rebuild) {
        return;
      }

      final check = await lightningWallet!.checkUnilateralExit(exit.recovery);
      final checked = exit.copyWith(recovery: check.recovery);

      switch (check.verdict) {
        case RecoveryVerdict_Done():
          await _saveUnilateralExit(checked.copyWith(status: UnilateralExitStatus.complete));
          await _setUnilateralExitCoinsFrozen(checked, isFrozen: false);
        case RecoveryVerdict_Redo():
          await _saveUnilateralExit(checked.copyWith(status: UnilateralExitStatus.rebuild));
        case RecoveryVerdict_Valid():
          await _setUnilateralExitCoinsFrozen(checked, isFrozen: true);

          final progress = await UnilateralExitBroadcaster(electrumClient: electrumClient)
              .broadcastReady(checked);

          await _saveUnilateralExit(
            checked.copyWith(
              status:
                  progress.isStalled ? UnilateralExitStatus.stalled : UnilateralExitStatus.active,
              inMempoolTxids: progress.inMempoolTxids,
            ),
          );
      }

      await _recordUnilateralExitHistory();
      await _refreshLightningBalance();
    } catch (e) {
      printV("unilateral exit: failed to advance: $e");
    } finally {
      _isAdvancingUnilateralExit = false;
    }
  }

  /// The funding coins and the CPFP change landing back on our addresses pay
  /// for later exit steps, so a regular send must not spend them first.
  Future<void> _setUnilateralExitCoinsFrozen(
    UnilateralExitPlan plan, {
    required bool isFrozen,
  }) async {
    final fundingTxids = plan.fundingTxids;
    final fundingOutpoints = plan.fundingOutpoints.toSet();
    final exitCoins = unspentCoins.where(
      (coin) =>
          fundingTxids.contains(coin.hash) ||
          fundingOutpoints.contains("${coin.hash}:${coin.vout}"),
    );

    for (final coin in exitCoins) {
      coin.isFrozen = isFrozen;

      final coinInfo = unspentCoinsInfo.values.firstWhereOrNull(
        (info) => info.walletId == id && info.hash == coin.hash && info.vout == coin.vout,
      );

      if (coinInfo != null && coinInfo.isFrozen != isFrozen) {
        coinInfo.isFrozen = isFrozen;
        await coinInfo.save();
      }
    }
  }

  Future<void> commitPsbtUR(List<String> urCodes) async {
    if (urCodes.isEmpty) throw ScanValueException("No QR code got scanned");
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
        accountIndex: currentAccountIndex,
        electrumClient: electrumClient,
        amount: Money.zero(currency),
        fee: Money.zero(currency),
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

  @override
  bool receiveOptionAvailable(ReceivePageOption option) {
    final isExtraAccount = currentAccountIndex > 0;

    if (option == BitcoinReceivePageOption.lightning) {
      // Lightning is tied to the primary account only
      return !isExtraAccount && hasLightningSupport && isLightningInitialized;
    }

    if (option == BitcoinReceivePageOption.silent_payments) {
      // Silent payments are tied to the primary account only
      return !isExtraAccount && hasSilentPaymentsScanning;
    }

    // Restrict extra Bitcoin accounts (accountIndex > 0) to the allowed address types
    if (isExtraAccount && option is BitcoinReceivePageOption) {
      final addressType = option.toType();
      if (!EXTRA_ACCOUNT_ADDRESS_TYPES.contains(addressType)) {
        return false;
      }
    }

    return true;
  }
}
