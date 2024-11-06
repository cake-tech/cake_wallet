import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_worker/methods/methods.dart';
import 'package:cw_bitcoin/psbt_transaction_builder.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:mobx/mobx.dart';
import 'package:sp_scanner/sp_scanner.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends ElectrumWallet with Store {
  StreamSubscription<dynamic>? _receiveStream;

  BitcoinWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    List<int>? seedBytes,
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
    required bool mempoolAPIEnabled,
    super.hdWallets,
  }) : super(
          mnemonic: mnemonic,
          passphrase: passphrase,
          xpub: xpub,
          password: password,
          walletInfo: walletInfo,
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
          mempoolAPIEnabled: mempoolAPIEnabled,
        ) {
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      network: networkParam ?? network,
      isHardwareWallet: walletInfo.isHardwareWallet,
      hdWallets: hdWallets,
    );

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  static Future<BitcoinWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
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
    required bool mempoolAPIEnabled,
  }) async {
    late List<int> seedBytes;
    final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets = {};

    for (final derivation in walletInfo.derivations ?? <DerivationInfo>[]) {
      if (derivation.derivationType == DerivationType.bip39) {
        seedBytes = Bip39SeedGenerator.generateFromString(mnemonic, passphrase);
        hdWallets[CWBitcoinDerivationType.bip39] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
        break;
      } else {
        try {
          seedBytes = ElectrumV2SeedGenerator.generateFromString(mnemonic, passphrase);
          hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
        } catch (e) {
          print("electrum_v2 seed error: $e");

          try {
            seedBytes = ElectrumV1SeedGenerator(mnemonic).generate();
            hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
          } catch (e) {
            print("electrum_v1 seed error: $e");
          }
        }

        break;
      }
    }

    hdWallets[CWBitcoinDerivationType.old] =
        hdWallets[CWBitcoinDerivationType.bip39] ?? hdWallets[CWBitcoinDerivationType.electrum]!;

    return BitcoinWallet(
      mnemonic: mnemonic,
      passphrase: passphrase ?? "",
      password: password,
      walletInfo: walletInfo,
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
      mempoolAPIEnabled: mempoolAPIEnabled,
      hdWallets: hdWallets,
    );
  }

  static Future<BitcoinWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required EncryptionFileUtils encryptionFileUtils,
    required bool alwaysScan,
    required bool mempoolAPIEnabled,
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

    walletInfo.derivationInfo ??= DerivationInfo();

    // set the default if not present:
    walletInfo.derivationInfo!.derivationPath ??= snp?.derivationPath ?? electrum_path;
    walletInfo.derivationInfo!.derivationType ??= snp?.derivationType ?? DerivationType.electrum;

    List<int>? seedBytes = null;
    final Map<CWBitcoinDerivationType, Bip32Slip10Secp256k1> hdWallets = {};
    final mnemonic = keysData.mnemonic;
    final passphrase = keysData.passphrase;

    if (mnemonic != null) {
      for (final derivation in walletInfo.derivations ?? <DerivationInfo>[]) {
        if (derivation.derivationType == DerivationType.bip39) {
          seedBytes = Bip39SeedGenerator.generateFromString(mnemonic, passphrase);
          hdWallets[CWBitcoinDerivationType.bip39] = Bip32Slip10Secp256k1.fromSeed(seedBytes);

          break;
        } else {
          try {
            seedBytes = ElectrumV2SeedGenerator.generateFromString(mnemonic, passphrase);
            hdWallets[CWBitcoinDerivationType.electrum] = Bip32Slip10Secp256k1.fromSeed(seedBytes);
          } catch (e) {
            print("electrum_v2 seed error: $e");

            try {
              seedBytes = ElectrumV1SeedGenerator(mnemonic).generate();
              hdWallets[CWBitcoinDerivationType.electrum] =
                  Bip32Slip10Secp256k1.fromSeed(seedBytes);
            } catch (e) {
              print("electrum_v1 seed error: $e");
            }
          }

          break;
        }
      }

      hdWallets[CWBitcoinDerivationType.old] =
          hdWallets[CWBitcoinDerivationType.bip39] ?? hdWallets[CWBitcoinDerivationType.electrum]!;
    }

    return BitcoinWallet(
      mnemonic: mnemonic,
      xpub: keysData.xPub,
      password: password,
      passphrase: passphrase,
      walletInfo: walletInfo,
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
      alwaysScan: alwaysScan,
      mempoolAPIEnabled: mempoolAPIEnabled,
      hdWallets: hdWallets,
    );
  }

  Future<bool> getNodeIsElectrs() async {
    final version = await sendWorker(ElectrumWorkerGetVersionRequest()) as List<String>;

    if (version.isNotEmpty) {
      final server = version[0];

      if (server.toLowerCase().contains('electrs')) {
        node!.isElectrs = true;
        node!.save();
        return node!.isElectrs!;
      }
    }

    node!.isElectrs = false;
    node!.save();
    return node!.isElectrs!;
  }

  Future<bool> getNodeSupportsSilentPayments() async {
    return true;
    // As of today (august 2024), only ElectrumRS supports silent payments
    // if (!(await getNodeIsElectrs())) {
    //   return false;
    // }

    // if (node == null) {
    //   return false;
    // }

    // try {
    //   final tweaksResponse = await electrumClient.getTweaks(height: 0);

    //   if (tweaksResponse != null) {
    //     node!.supportsSilentPayments = true;
    //     node!.save();
    //     return node!.supportsSilentPayments!;
    //   }
    // } on RequestFailedTimeoutException catch (_) {
    //   node!.supportsSilentPayments = false;
    //   node!.save();
    //   return node!.supportsSilentPayments!;
    // } catch (_) {}

    // node!.supportsSilentPayments = false;
    // node!.save();
    // return node!.supportsSilentPayments!;
  }

  LedgerConnection? _ledgerConnection;
  BitcoinLedgerApp? _bitcoinLedgerApp;

  @override
  void setLedgerConnection(LedgerConnection connection) {
    _ledgerConnection = connection;
    _bitcoinLedgerApp = BitcoinLedgerApp(_ledgerConnection!,
        derivationPath: walletInfo.derivationInfo!.derivationPath!);
  }

  @override
  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinBaseOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final masterFingerprint = await _bitcoinLedgerApp!.getMasterFingerprint();

    final psbtReadyInputs = <PSBTReadyUtxoWithAddress>[];
    for (final utxo in utxos) {
      final rawTx =
          (await getTransactionExpanded(hash: utxo.utxo.txHash)).originalTransaction.toHex();
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

    final psbt =
        PSBTTransactionBuild(inputs: psbtReadyInputs, outputs: outputs, enableRBF: enableRBF);

    final rawHex = await _bitcoinLedgerApp!.signPsbt(psbt: psbt.psbt);
    return BtcTransaction.fromRaw(BytesUtils.toHexString(rawHex));
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    if (walletInfo.isHardwareWallet) {
      final addressEntry = address != null
          ? walletAddresses.allAddresses.firstWhere((element) => element.address == address)
          : null;
      final index = addressEntry?.index ?? 0;
      final isChange = addressEntry?.isChange == true ? 1 : 0;
      final accountPath = walletInfo.derivationInfo?.derivationPath;
      final derivationPath = accountPath != null ? "$accountPath/$isChange/$index" : null;

      final signature = await _bitcoinLedgerApp!
          .signMessage(message: ascii.encode(message), signDerivationPath: derivationPath);
      return base64Encode(signature);
    }

    return super.signMessage(message, address: address);
  }

  @action
  Future<void> setSilentPaymentsScanning(bool active) async {
    silentPaymentsScanningActive = active;

    if (active) {
      syncStatus = AttemptingScanSyncStatus();

      final tip = currentChainTip!;

      if (tip == walletInfo.restoreHeight) {
        syncStatus = SyncedTipSyncStatus(tip);
        return;
      }

      if (tip > walletInfo.restoreHeight) {
        _setListeners(walletInfo.restoreHeight);
      }
    } else {
      alwaysScan = false;

      // _isolate?.then((value) => value.kill(priority: Isolate.immediate));

      // if (rpc!.isConnected) {
      //   syncStatus = SyncedSyncStatus();
      // } else {
      //   syncStatus = NotConnectedSyncStatus();
      // }
    }
  }

  // @override
  // @action
  // Future<void> updateAllUnspents() async {
  //   List<BitcoinUnspent> updatedUnspentCoins = [];

  //   // Update unspents stored from scanned silent payment transactions
  //   transactionHistory.transactions.values.forEach((tx) {
  //     if (tx.unspents != null) {
  //       updatedUnspentCoins.addAll(tx.unspents!);
  //     }
  //   });

  //   // Set the balance of all non-silent payment and non-mweb addresses to 0 before updating
  //   walletAddresses.allAddresses
  //       .where((element) => element.type != SegwitAddresType.mweb)
  //       .forEach((addr) {
  //     if (addr is! BitcoinSilentPaymentAddressRecord) addr.balance = 0;
  //   });

  //   await Future.wait(walletAddresses.allAddresses
  //       .where((element) => element.type != SegwitAddresType.mweb)
  //       .map((address) async {
  //     updatedUnspentCoins.addAll(await fetchUnspent(address));
  //   }));

  //   unspentCoins.addAll(updatedUnspentCoins);

  //   if (unspentCoinsInfo.length != updatedUnspentCoins.length) {
  //     unspentCoins.forEach((coin) => addCoinInfo(coin));
  //     return;
  //   }

  //   await updateCoins(unspentCoins.toSet());
  //   await refreshUnspentCoinsInfo();
  // }

  @override
  void updateCoin(BitcoinUnspent coin) {
    final coinInfoList = unspentCoinsInfo.values.where(
      (element) =>
          element.walletId.contains(id) &&
          element.hash.contains(coin.hash) &&
          element.vout == coin.vout,
    );

    if (coinInfoList.isNotEmpty) {
      final coinInfo = coinInfoList.first;

      coin.isFrozen = coinInfo.isFrozen;
      coin.isSending = coinInfo.isSending;
      coin.note = coinInfo.note;
      if (coin.bitcoinAddressRecord is! BitcoinSilentPaymentAddressRecord)
        coin.bitcoinAddressRecord.balance += coinInfo.value;
    } else {
      addCoinInfo(coin);
    }
  }

  @action
  @override
  Future<void> startSync() async {
    await _setInitialScanHeight();

    await super.startSync();

    if (alwaysScan == true) {
      _setListeners(walletInfo.restoreHeight);
    }
  }

  @action
  @override
  Future<void> rescan({required int height, bool? doSingleScan}) async {
    silentPaymentsScanningActive = true;
    _setListeners(height, doSingleScan: doSingleScan);
  }

  // @action
  // Future<void> registerSilentPaymentsKey(bool register) async {
  //   silentPaymentsScanningActive = active;

  //   if (active) {
  //     syncStatus = AttemptingScanSyncStatus();

  //     final tip = await getUpdatedChainTip();

  //     if (tip == walletInfo.restoreHeight) {
  //       syncStatus = SyncedTipSyncStatus(tip);
  //       return;
  //     }

  //     if (tip > walletInfo.restoreHeight) {
  //       _setListeners(walletInfo.restoreHeight, chainTipParam: _currentChainTip);
  //     }
  //   } else {
  //     alwaysScan = false;

  //     _isolate?.then((value) => value.kill(priority: Isolate.immediate));

  //     if (electrumClient.isConnected) {
  //       syncStatus = SyncedSyncStatus();
  //     } else {
  //       syncStatus = NotConnectedSyncStatus();
  //     }
  //   }
  // }

  @action
  Future<void> registerSilentPaymentsKey() async {
    // final registered = await electrumClient.tweaksRegister(
    //   secViewKey: walletAddresses.silentAddress!.b_scan.toHex(),
    //   pubSpendKey: walletAddresses.silentAddress!.B_spend.toHex(),
    //   labels: walletAddresses.silentAddresses
    //       .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.labelIndex >= 1)
    //       .map((addr) => addr.labelIndex)
    //       .toList(),
    // );

    // print("registered: $registered");
  }

  @action
  void _updateSilentAddressRecord(BitcoinUnspent unspent) {
    final receiveAddressRecord = unspent.bitcoinAddressRecord as BitcoinReceivedSPAddressRecord;
    final silentAddress = walletAddresses.silentAddress!;
    final silentPaymentAddress = SilentPaymentAddress(
      version: silentAddress.version,
      B_scan: silentAddress.B_scan,
      B_spend: receiveAddressRecord.labelHex != null
          ? silentAddress.B_spend.tweakAdd(
              BigintUtils.fromBytes(BytesUtils.fromHexString(receiveAddressRecord.labelHex!)),
            )
          : silentAddress.B_spend,
    );

    final addressRecord = walletAddresses.silentAddresses
        .firstWhere((address) => address.address == silentPaymentAddress.toString());
    addressRecord.txCount += 1;
    addressRecord.balance += unspent.value;

    walletAddresses.addSilentAddresses(
      [unspent.bitcoinAddressRecord as BitcoinSilentPaymentAddressRecord],
    );
  }

  @override
  @action
  Future<void> handleWorkerResponse(dynamic message) async {
    super.handleWorkerResponse(message);

    Map<String, dynamic> messageJson;
    if (message is String) {
      messageJson = jsonDecode(message) as Map<String, dynamic>;
    } else {
      messageJson = message as Map<String, dynamic>;
    }
    final workerMethod = messageJson['method'] as String;

    switch (workerMethod) {
      case ElectrumRequestMethods.tweaksSubscribeMethod:
        final response = ElectrumWorkerTweaksSubscribeResponse.fromJson(messageJson);
        onTweaksSyncResponse(response.result);
        break;
    }
  }

  @action
  Future<void> onTweaksSyncResponse(TweaksSyncResponse result) async {
    if (result.transactions?.isNotEmpty == true) {
      for (final map in result.transactions!.entries) {
        final txid = map.key;
        final tx = map.value;

        if (tx.unspents != null) {
          final existingTxInfo = transactionHistory.transactions[txid];
          final txAlreadyExisted = existingTxInfo != null;

          // Updating tx after re-scanned
          if (txAlreadyExisted) {
            existingTxInfo.amount = tx.amount;
            existingTxInfo.confirmations = tx.confirmations;
            existingTxInfo.height = tx.height;

            final newUnspents = tx.unspents!
                .where((unspent) => !(existingTxInfo.unspents?.any((element) =>
                        element.hash.contains(unspent.hash) &&
                        element.vout == unspent.vout &&
                        element.value == unspent.value) ??
                    false))
                .toList();

            if (newUnspents.isNotEmpty) {
              newUnspents.forEach(_updateSilentAddressRecord);

              existingTxInfo.unspents ??= [];
              existingTxInfo.unspents!.addAll(newUnspents);

              final newAmount = newUnspents.length > 1
                  ? newUnspents.map((e) => e.value).reduce((value, unspent) => value + unspent)
                  : newUnspents[0].value;

              if (existingTxInfo.direction == TransactionDirection.incoming) {
                existingTxInfo.amount += newAmount;
              }

              // Updates existing TX
              transactionHistory.addOne(existingTxInfo);
              // Update balance record
              balance[currency]!.confirmed += newAmount;
            }
          } else {
            // else: First time seeing this TX after scanning
            tx.unspents!.forEach(_updateSilentAddressRecord);

            // Add new TX record
            transactionHistory.addOne(tx);
            // Update balance record
            balance[currency]!.confirmed += tx.amount;
          }

          await updateAllUnspents();
        }
      }
    }

    final newSyncStatus = result.syncStatus;

    if (newSyncStatus != null) {
      if (newSyncStatus is UnsupportedSyncStatus) {
        nodeSupportsSilentPayments = false;
      }

      if (newSyncStatus is SyncingSyncStatus) {
        syncStatus = SyncingSyncStatus(newSyncStatus.blocksLeft, newSyncStatus.ptc);
      } else {
        syncStatus = newSyncStatus;
      }

      await walletInfo.updateRestoreHeight(result.height!);
    }
  }

  @action
  Future<void> _setListeners(int height, {bool? doSingleScan}) async {
    if (currentChainTip == null) {
      throw Exception("currentChainTip is null");
    }

    final chainTip = currentChainTip!;

    if (chainTip == height) {
      syncStatus = SyncedSyncStatus();
      return;
    }

    syncStatus = AttemptingScanSyncStatus();

    workerSendPort!.send(
      ElectrumWorkerTweaksSubscribeRequest(
        scanData: ScanData(
          silentAddress: walletAddresses.silentAddress!,
          network: network,
          height: height,
          chainTip: chainTip,
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          labels: walletAddresses.labels,
          labelIndexes: walletAddresses.silentAddresses
              .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.labelIndex >= 1)
              .map((addr) => addr.labelIndex)
              .toList(),
          isSingleScan: doSingleScan ?? false,
        ),
      ).toJson(),
    );
  }

  @override
  @action
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    throw UnimplementedError();
    // try {
    //   final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

    //   await Future.wait(
    //     BITCOIN_ADDRESS_TYPES.map(
    //       (type) => fetchTransactionsForAddressType(historiesWithDetails, type),
    //     ),
    //   );

    //   transactionHistory.transactions.values.forEach((tx) async {
    //     final isPendingSilentPaymentUtxo =
    //         (tx.isPending || tx.confirmations == 0) && historiesWithDetails[tx.id] == null;

    //     if (isPendingSilentPaymentUtxo) {
    //       final info = await fetchTransactionInfo(hash: tx.id, height: tx.height);

    //       if (info != null) {
    //         tx.confirmations = info.confirmations;
    //         tx.isPending = tx.confirmations == 0;
    //         transactionHistory.addOne(tx);
    //         await transactionHistory.save();
    //       }
    //     }
    //   });

    //   return historiesWithDetails;
    // } catch (e) {
    //   print("fetchTransactions $e");
    //   return {};
    // }
  }

  @override
  @action
  Future<void> updateTransactions([List<BitcoinAddressRecord>? addresses]) async {
    super.updateTransactions();

    transactionHistory.transactions.values.forEach((tx) {
      if (tx.unspents != null &&
          tx.unspents!.isNotEmpty &&
          tx.height != null &&
          tx.height! > 0 &&
          (currentChainTip ?? 0) > 0) {
        tx.confirmations = currentChainTip! - tx.height! + 1;
      }
    });
  }

  // @action
  // Future<ElectrumBalance> fetchBalances() async {
  //   final balance = await super.fetchBalances();

  //   int totalFrozen = balance.frozen;
  //   int totalConfirmed = balance.confirmed;

  //   // Add values from unspent coins that are not fetched by the address list
  //   // i.e. scanned silent payments
  //   transactionHistory.transactions.values.forEach((tx) {
  //     if (tx.unspents != null) {
  //       tx.unspents!.forEach((unspent) {
  //         if (unspent.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
  //           if (unspent.isFrozen) totalFrozen += unspent.value;
  //           totalConfirmed += unspent.value;
  //         }
  //       });
  //     }
  //   });

  //   return ElectrumBalance(
  //     confirmed: totalConfirmed,
  //     unconfirmed: balance.unconfirmed,
  //     frozen: totalFrozen,
  //   );
  // }

  @override
  @action
  Future<void> onHeadersResponse(ElectrumHeaderResponse response) async {
    super.onHeadersResponse(response);

    _setInitialScanHeight();

    // New headers received, start scanning
    if (alwaysScan == true && syncStatus is SyncedSyncStatus) {
      _setListeners(walletInfo.restoreHeight);
    }
  }

  Future<void> _setInitialScanHeight() async {
    final validChainTip = currentChainTip != null && currentChainTip != 0;
    if (validChainTip && walletInfo.restoreHeight == 0) {
      await walletInfo.updateRestoreHeight(currentChainTip!);
    }
  }

  static String _hardenedDerivationPath(String derivationPath) =>
      derivationPath.substring(0, derivationPath.lastIndexOf("'") + 1);

  @override
  @action
  void syncStatusReaction(SyncStatus syncStatus) {
    switch (syncStatus.runtimeType) {
      case SyncingSyncStatus:
        return;
      case SyncedTipSyncStatus:
        // Message is shown on the UI for 3 seconds, then reverted to synced
        Timer(Duration(seconds: 3), () {
          if (this.syncStatus is SyncedTipSyncStatus) this.syncStatus = SyncedSyncStatus();
        });
        break;
      default:
        super.syncStatusReaction(syncStatus);
    }
  }
}
