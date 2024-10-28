import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
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
  Future<Isolate>? _isolate;
  StreamSubscription<dynamic>? _receiveStream;

  BitcoinWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
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
    required bool mempoolAPIEnabled,
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
      bip32: bip32,
      network: networkParam ?? network,
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
    late Uint8List seedBytes;

    switch (walletInfo.derivationInfo?.derivationType) {
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

    Uint8List? seedBytes = null;
    final mnemonic = keysData.mnemonic;
    final passphrase = keysData.passphrase;

    if (mnemonic != null) {
      switch (walletInfo.derivationInfo!.derivationType) {
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
    );
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

      _isolate?.then((value) => value.kill(priority: Isolate.immediate));

      if (rpc!.isConnected) {
        syncStatus = SyncedSyncStatus();
      } else {
        syncStatus = NotConnectedSyncStatus();
      }
    }
  }

  @override
  @action
  Future<void> updateAllUnspents() async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    // Update unspents stored from scanned silent payment transactions
    transactionHistory.transactions.values.forEach((tx) {
      if (tx.unspents != null) {
        updatedUnspentCoins.addAll(tx.unspents!);
      }
    });

    // Set the balance of all non-silent payment and non-mweb addresses to 0 before updating
    walletAddresses.allAddresses
        .where((element) => element.type != SegwitAddresType.mweb)
        .forEach((addr) {
      if (addr is! BitcoinSilentPaymentAddressRecord) addr.balance = 0;
    });

    await Future.wait(walletAddresses.allAddresses
        .where((element) => element.type != SegwitAddresType.mweb)
        .map((address) async {
      updatedUnspentCoins.addAll(await fetchUnspent(address));
    }));

    unspentCoins = updatedUnspentCoins;

    if (unspentCoinsInfo.length != updatedUnspentCoins.length) {
      unspentCoins.forEach((coin) => addCoinInfo(coin));
      return;
    }

    await updateCoins(unspentCoins);
    await refreshUnspentCoinsInfo();
  }

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

  Future<void> _setInitialHeight() async {
    final validChainTip = currentChainTip != null && currentChainTip != 0;
    if (validChainTip && walletInfo.restoreHeight == 0) {
      await walletInfo.updateRestoreHeight(currentChainTip!);
    }
  }

  @action
  @override
  Future<void> startSync() async {
    await _setInitialHeight();

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

    if (_isolate != null) {
      final runningIsolate = await _isolate!;
      runningIsolate.kill(priority: Isolate.immediate);
    }

    final receivePort = ReceivePort();
    _isolate = Isolate.spawn(
        startRefresh,
        ScanData(
          sendPort: receivePort.sendPort,
          silentAddress: walletAddresses.silentAddress!,
          network: network,
          height: height,
          chainTip: chainTip,
          transactionHistoryIds: transactionHistory.transactions.keys.toList(),
          node: (await getNodeSupportsSilentPayments()) == true
              ? ScanNode(node!.uri, node!.useSSL)
              : null,
          labels: walletAddresses.labels,
          labelIndexes: walletAddresses.silentAddresses
              .where((addr) => addr.type == SilentPaymentsAddresType.p2sp && addr.labelIndex >= 1)
              .map((addr) => addr.labelIndex)
              .toList(),
          isSingleScan: doSingleScan ?? false,
        ));

    _receiveStream?.cancel();
    _receiveStream = receivePort.listen((var message) async {
      if (message is Map<String, ElectrumTransactionInfo>) {
        for (final map in message.entries) {
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
              transactionHistory.addMany(message);
              // Update balance record
              balance[currency]!.confirmed += tx.amount;
            }

            await updateAllUnspents();
          }
        }
      }

      if (message is SyncResponse) {
        if (message.syncStatus is UnsupportedSyncStatus) {
          nodeSupportsSilentPayments = false;
        }

        if (message.syncStatus is SyncingSyncStatus) {
          var status = message.syncStatus as SyncingSyncStatus;
          syncStatus = SyncingSyncStatus(status.blocksLeft, status.ptc);
        } else {
          syncStatus = message.syncStatus;
        }

        await walletInfo.updateRestoreHeight(message.height);
      }
    });
  }

  @override
  @action
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    try {
      final Map<String, ElectrumTransactionInfo> historiesWithDetails = {};

      await Future.wait(
        BITCOIN_ADDRESS_TYPES.map(
          (type) => fetchTransactionsForAddressType(historiesWithDetails, type),
        ),
      );

      transactionHistory.transactions.values.forEach((tx) async {
        final isPendingSilentPaymentUtxo =
            (tx.isPending || tx.confirmations == 0) && historiesWithDetails[tx.id] == null;

        if (isPendingSilentPaymentUtxo) {
          final info = await fetchTransactionInfo(hash: tx.id, height: tx.height);

          if (info != null) {
            tx.confirmations = info.confirmations;
            tx.isPending = tx.confirmations == 0;
            transactionHistory.addOne(tx);
            await transactionHistory.save();
          }
        }
      });

      return historiesWithDetails;
    } catch (e) {
      print("fetchTransactions $e");
      return {};
    }
  }

  @override
  @action
  Future<void> updateTransactions() async {
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

  @action
  Future<ElectrumBalance> fetchBalances(List<BitcoinAddressRecord> addresses) async {
    final balance = await super.fetchBalances(addresses);

    int totalFrozen = balance.frozen;
    int totalConfirmed = balance.confirmed;

    // Add values from unspent coins that are not fetched by the address list
    // i.e. scanned silent payments
    transactionHistory.transactions.values.forEach((tx) {
      if (tx.unspents != null) {
        tx.unspents!.forEach((unspent) {
          if (unspent.bitcoinAddressRecord is BitcoinSilentPaymentAddressRecord) {
            if (unspent.isFrozen) totalFrozen += unspent.value;
            totalConfirmed += unspent.value;
          }
        });
      }
    });

    return ElectrumBalance(
      confirmed: totalConfirmed,
      unconfirmed: balance.unconfirmed,
      frozen: totalFrozen,
    );
  }

  @override
  @action
  Future<void> updateFeeRates() async {
    // Bitcoin only: use the mempool.space backend API for accurate fee rates
    if (mempoolAPIEnabled) {
      try {
        final recommendedFees = await apiProvider!.getRecommendedFeeRate();

        final unimportantFee = recommendedFees.economyFee!.satoshis;
        final normalFee = recommendedFees.low.satoshis;
        int elevatedFee = recommendedFees.medium.satoshis;
        int priorityFee = recommendedFees.high.satoshis;

        // Bitcoin only: adjust fee rates to avoid equal fee values
        // elevated should be higher than normal
        if (normalFee == elevatedFee) {
          elevatedFee++;
        }
        // priority should be higher than elevated
        while (priorityFee <= elevatedFee) {
          priorityFee++;
        }
        // this guarantees that, even if all fees are low and equal,
        // higher priority fees can be taken when fees start surging

        feeRates = BitcoinMempoolAPITransactionPriorities(
          unimportant: unimportantFee,
          normal: normalFee,
          elevated: elevatedFee,
          priority: priorityFee,
        );
        return;
      } catch (e, stacktrace) {
        callError(FlutterErrorDetails(
          exception: e,
          stack: stacktrace,
          library: this.runtimeType.toString(),
        ));
      }
    } else {
      // Bitcoin only: Ideally this should be avoided, electrum is terrible at fee rates
      await super.updateFeeRates();
    }
  }

  @override
  @action
  void onHeadersResponse(ElectrumHeaderResponse response) {
    super.onHeadersResponse(response);

    if (alwaysScan == true && syncStatus is SyncedSyncStatus) {
      _setListeners(walletInfo.restoreHeight);
    }
  }

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

Future<void> startRefresh(ScanData scanData) async {
  int syncHeight = scanData.height;
  int initialSyncHeight = syncHeight;

  final electrumClient = ElectrumApiProvider(
    await ElectrumTCPService.connect(
      scanData.node?.uri ?? Uri.parse("tcp://198.58.115.71:50001"),
    ),
  );

  int getCountPerRequest(int syncHeight) {
    if (scanData.isSingleScan) {
      return 1;
    }

    final amountLeft = scanData.chainTip - syncHeight + 1;
    return amountLeft;
  }

  final receiver = Receiver(
    scanData.silentAddress.b_scan.toHex(),
    scanData.silentAddress.B_spend.toHex(),
    scanData.network == BitcoinNetwork.testnet,
    scanData.labelIndexes,
    scanData.labelIndexes.length,
  );

  // Initial status UI update, send how many blocks in total to scan
  final initialCount = getCountPerRequest(syncHeight);
  scanData.sendPort.send(SyncResponse(syncHeight, StartingScanSyncStatus(syncHeight)));

  final listener = await electrumClient.subscribe(
    ElectrumTweaksSubscribe(height: syncHeight, count: initialCount),
  );

  Future<void> listenFn(ElectrumTweaksSubscribeResponse response) async {
    // success or error msg
    final noData = response.message != null;

    if (noData) {
      // re-subscribe to continue receiving messages, starting from the next unscanned height
      final nextHeight = syncHeight + 1;
      final nextCount = getCountPerRequest(nextHeight);

      if (nextCount > 0) {
        final nextListener = await electrumClient.subscribe(
          ElectrumTweaksSubscribe(height: syncHeight, count: initialCount),
        );
        nextListener?.call(listenFn);
      }

      return;
    }

    // Continuous status UI update, send how many blocks left to scan
    final syncingStatus = scanData.isSingleScan
        ? SyncingSyncStatus(1, 0)
        : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, syncHeight);
    scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

    final tweakHeight = response.block;

    try {
      final blockTweaks = response.blockTweaks;

      for (final txid in blockTweaks.keys) {
        final tweakData = blockTweaks[txid];
        final outputPubkeys = tweakData!.outputPubkeys;
        final tweak = tweakData.tweak;

        try {
          // scanOutputs called from rust here
          final addToWallet = scanOutputs(outputPubkeys.keys.toList(), tweak, receiver);

          if (addToWallet.isEmpty) {
            // no results tx, continue to next tx
            continue;
          }

          // placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s)
          final txInfo = ElectrumTransactionInfo(
            WalletType.bitcoin,
            id: txid,
            height: tweakHeight,
            amount: 0,
            fee: 0,
            direction: TransactionDirection.incoming,
            isPending: false,
            isReplaced: false,
            date: scanData.network == BitcoinNetwork.mainnet
                ? getDateByBitcoinHeight(tweakHeight)
                : DateTime.now(),
            confirmations: scanData.chainTip - tweakHeight + 1,
            unspents: [],
            isReceivedSilentPayment: true,
          );

          addToWallet.forEach((label, value) {
            (value as Map<String, dynamic>).forEach((output, tweak) {
              final t_k = tweak.toString();

              final receivingOutputAddress = ECPublic.fromHex(output)
                  .toTaprootAddress(tweak: false)
                  .toAddress(scanData.network);

              final matchingOutput = outputPubkeys[output]!;
              final amount = matchingOutput.amount;
              final pos = matchingOutput.vout;

              final receivedAddressRecord = BitcoinReceivedSPAddressRecord(
                receivingOutputAddress,
                labelIndex: 1, // TODO: get actual index/label
                isUsed: true,
                spendKey: scanData.silentAddress.b_spend.tweakAdd(
                  BigintUtils.fromBytes(BytesUtils.fromHexString(t_k)),
                ),
                txCount: 1,
                balance: amount,
              );

              final unspent = BitcoinUnspent(receivedAddressRecord, txid, amount, pos);

              txInfo.unspents!.add(unspent);
              txInfo.amount += unspent.value;
            });
          });

          scanData.sendPort.send({txInfo.id: txInfo});
        } catch (e, stacktrace) {
          print(stacktrace);
          print(e.toString());
        }
      }
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
    }

    syncHeight = tweakHeight;

    if (tweakHeight >= scanData.chainTip || scanData.isSingleScan) {
      if (tweakHeight >= scanData.chainTip)
        scanData.sendPort.send(SyncResponse(
          syncHeight,
          SyncedTipSyncStatus(scanData.chainTip),
        ));

      if (scanData.isSingleScan) {
        scanData.sendPort.send(SyncResponse(syncHeight, SyncedSyncStatus()));
      }
    }
  }

  listener?.call(listenFn);

  // if (tweaksSubscription == null) {
  //   return scanData.sendPort.send(
  //     SyncResponse(syncHeight, UnsupportedSyncStatus()),
  //   );
  // }
}

Future<void> delegatedScan(ScanData scanData) async {
  // int syncHeight = scanData.height;
  // int initialSyncHeight = syncHeight;

  // BehaviorSubject<Object>? tweaksSubscription = null;

  // final electrumClient = scanData.electrumClient;
  // await electrumClient.connectToUri(
  //   scanData.node?.uri ?? Uri.parse("tcp://electrs.cakewallet.com:50001"),
  //   useSSL: scanData.node?.useSSL ?? false,
  // );

  // if (tweaksSubscription == null) {
  //   scanData.sendPort.send(SyncResponse(syncHeight, StartingScanSyncStatus(syncHeight)));

  //   tweaksSubscription = await electrumClient.tweaksScan(
  //     pubSpendKey: scanData.silentAddress.B_spend.toHex(),
  //   );

  //   Future<void> listenFn(t) async {
  //     final tweaks = t as Map<String, dynamic>;
  //     final msg = tweaks["message"];

  //     // success or error msg
  //     final noData = msg != null;
  //     if (noData) {
  //       return;
  //     }

  //     // Continuous status UI update, send how many blocks left to scan
  //     final syncingStatus = scanData.isSingleScan
  //         ? SyncingSyncStatus(1, 0)
  //         : SyncingSyncStatus.fromHeightValues(scanData.chainTip, initialSyncHeight, syncHeight);
  //     scanData.sendPort.send(SyncResponse(syncHeight, syncingStatus));

  //     final blockHeight = tweaks.keys.first;
  //     final tweakHeight = int.parse(blockHeight);

  //     try {
  //       final blockTweaks = tweaks[blockHeight] as Map<String, dynamic>;

  //       for (var j = 0; j < blockTweaks.keys.length; j++) {
  //         final txid = blockTweaks.keys.elementAt(j);
  //         final details = blockTweaks[txid] as Map<String, dynamic>;
  //         final outputPubkeys = (details["output_pubkeys"] as Map<dynamic, dynamic>);
  //         final spendingKey = details["spending_key"].toString();

  //         try {
  //           // placeholder ElectrumTransactionInfo object to update values based on new scanned unspent(s)
  //           final txInfo = ElectrumTransactionInfo(
  //             WalletType.bitcoin,
  //             id: txid,
  //             height: tweakHeight,
  //             amount: 0,
  //             fee: 0,
  //             direction: TransactionDirection.incoming,
  //             isPending: false,
  //             isReplaced: false,
  //             date: scanData.network == BitcoinNetwork.mainnet
  //                 ? getDateByBitcoinHeight(tweakHeight)
  //                 : DateTime.now(),
  //             confirmations: scanData.chainTip - tweakHeight + 1,
  //             unspents: [],
  //             isReceivedSilentPayment: true,
  //           );

  //           outputPubkeys.forEach((pos, value) {
  //             final secKey = ECPrivate.fromHex(spendingKey);
  //             final receivingOutputAddress =
  //                 secKey.getPublic().toTaprootAddress(tweak: false).toAddress(scanData.network);

  //             late int amount;
  //             try {
  //               amount = int.parse(value[1].toString());
  //             } catch (_) {
  //               return;
  //             }

  //             final receivedAddressRecord = BitcoinReceivedSPAddressRecord(
  //               receivingOutputAddress,
  //               labelIndex: 0,
  //               isUsed: true,
  //               spendKey: secKey,
  //               txCount: 1,
  //               balance: amount,
  //             );

  //             final unspent = BitcoinUnspent(
  //               receivedAddressRecord,
  //               txid,
  //               amount,
  //               int.parse(pos.toString()),
  //             );

  //             txInfo.unspents!.add(unspent);
  //             txInfo.amount += unspent.value;
  //           });

  //           scanData.sendPort.send({txInfo.id: txInfo});
  //         } catch (_) {}
  //       }
  //     } catch (_) {}

  //     syncHeight = tweakHeight;

  //     if (tweakHeight >= scanData.chainTip || scanData.isSingleScan) {
  //       if (tweakHeight >= scanData.chainTip)
  //         scanData.sendPort.send(SyncResponse(
  //           syncHeight,
  //           SyncedTipSyncStatus(scanData.chainTip),
  //         ));

  //       if (scanData.isSingleScan) {
  //         scanData.sendPort.send(SyncResponse(syncHeight, SyncedSyncStatus()));
  //       }

  //       await tweaksSubscription!.close();
  //       await electrumClient.close();
  //     }
  //   }

  //   tweaksSubscription?.listen(listenFn);
  // }

  // if (tweaksSubscription == null) {
  //   return scanData.sendPort.send(
  //     SyncResponse(syncHeight, UnsupportedSyncStatus()),
  //   );
  // }
}
