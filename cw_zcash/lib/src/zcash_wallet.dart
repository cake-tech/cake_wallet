import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/util/crc32.dart';
import 'package:cw_zcash/src/zcash_taddress_rotation.dart';
import 'package:cw_zcash/src/zcash_wallet_addresses.dart';
import 'package:mobx/mobx.dart';
import 'package:warp_api/warp_api.dart';
import 'package:warp_api/data_fb_generated.dart';
import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

part 'zcash_wallet.g.dart';

class ZcashWallet = ZcashWalletBase with _$ZcashWallet;

abstract class ZcashWalletBase
    extends WalletBase<ZcashBalance, ZcashTransactionHistory, ZcashTransactionInfo>
    with Store {
  ZcashWalletBase(super.walletInfo, super.derivationInfo, {required this.accountId}) {
    transactionHistory = ZcashTransactionHistory();
  }

  final int accountId;
  static const int coin = 0; // Zcash mainnet coin ID in warp_api
  @override
  @observable
  SyncStatus syncStatus = NotConnectedSyncStatus();

  Timer? _syncStatusTimer;
  Timer? _periodicSyncTimer;
  int _initialSyncHeight = 0;
  int _lastKnownBlockHeight = 0;

  @override
  ObservableMap<CryptoCurrency, ZcashBalance> balance = ObservableMap.of({
    CryptoCurrency.zec: ZcashBalance(confirmed: 0, unconfirmed: 0, frozen: 0),
  });

  static int internalCalculateEstimatedFee(final TransactionPriority priority, final int? amount) {
    const baseFee = 10000;
    switch (priority) {
      case MoneroTransactionPriority.slow:
      case MoneroTransactionPriority.automatic:
        return baseFee;
      case MoneroTransactionPriority.medium:
        return baseFee * 2;
      case MoneroTransactionPriority.fast:
        return baseFee * 4;
      case MoneroTransactionPriority.fastest:
        return baseFee * 10;
    }
    ;
    return internalCalculateEstimatedFee(MoneroTransactionPriority.automatic, amount);
  }

  @override
  int calculateEstimatedFee(final TransactionPriority priority, final int? amount) {
    return internalCalculateEstimatedFee(priority, amount);
  }

  @override
  Future<void> changePassword(final String password) async {
    // throw UnimplementedError();
  }

  static bool isNodeWorking = true;

  @override
  Future<bool> checkNodeHealth() {
    return Future.value(isNodeWorking);
  }

  @override
  Future<void> close({final bool shouldCleanup = false}) async {
    _stopSyncStatusUpdates();
    _stopPeriodicSync();
    await ZcashWalletService.runInDbMutex(() async => WarpApi.cancelSync());
  }

  @override
  @action
  Future<void> connectToNode({required final Node node}) async {
    printV("connecting to node: ${node.uriRaw}");
    syncStatus = ConnectingSyncStatus();
    try {
      String lwdUrl = node.uriRaw;
      if (!lwdUrl.startsWith('http://') && !lwdUrl.startsWith('https://')) {
        final protocol = node.useSSL == true ? 'https://' : 'http://';
        lwdUrl = '$protocol$lwdUrl';
      }
      printV("Setting LWD URL to: $lwdUrl");
      WarpApi.updateLWD(coin, lwdUrl);
      syncStatus = ConnectedSyncStatus();
      try {
        await updateBalance();
        await updateTransactions();
      } catch (e) {
        printV("Error updating balance/transactions after connect: $e");
      }
    } catch (e) {
      printV("Connection error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    }
  }

  @override
  Future<PendingTransaction> createTransaction(final Object credentials) async {
    final creds = credentials as ZcashTransactionCredentials;
    await updateBalance();

    final zcashBalance = balance[CryptoCurrency.zec];
    final availableBalance = zcashBalance?.confirmed ?? 0;

    final recipients = <Recipient>[];
    int totalAmount = 0;

    for (final output in creds.outputs) {
      int amount;
      if (output.sendAll) {
        amount = availableBalance - internalCalculateEstimatedFee(creds.priority, null);
        if (amount <= 0) {
          throw Exception('Insufficient balance for send all (including fee)');
        }
      } else {
        amount = output.formattedCryptoAmount ?? 0;

        if (amount == 0 && output.cryptoAmount != null && output.cryptoAmount!.isNotEmpty) {
          try {
            final parsedAmount = CryptoCurrency.zec.parseAmount(
              output.cryptoAmount!.replaceAll(',', '.'),
            );
            amount = parsedAmount.toInt();
            printV("Parsed amount from cryptoAmount '${output.cryptoAmount}': $amount");
          } catch (e) {
            printV("Failed to parse cryptoAmount '${output.cryptoAmount}': $e");
          }
        }

        if (amount <= 0) {
          throw Exception(
            'Invalid amount for output. Amount: ${output.cryptoAmount}, Formatted: ${output.formattedCryptoAmount}',
          );
        }
      }

      totalAmount += amount;

      var address = (output.isParsedAddress ? output.extractedAddress! : output.address).trim();

      if (address.isEmpty) {
        throw Exception('Empty address for output');
      }

      final paymentUri = WarpApi.decodePaymentURI(coin, address);
      String memo = output.note ?? '';
      if (paymentUri != null && paymentUri.address != null) {
        address = paymentUri.address!;
        if (memo.isEmpty && paymentUri.memo != null) {
          memo = paymentUri.memo!;
        }
      }

      if (!WarpApi.validAddress(coin, address)) {
        throw Exception('Invalid Zcash address: $address');
      }

      int recipientPools = 7;

      if (address.startsWith('t1') || address.startsWith('t3')) {
        recipientPools = 1; // Transparent only
      } else if (address.startsWith('zs')) {
        recipientPools = 2; // Sapling only
      }
      // For unified addresses (u1...) and other types, use 7 (all pools)

      final builder = RecipientObjectBuilder(
        address: address,
        pools: recipientPools,
        amount: amount,
        feeIncluded: output.sendAll,
        replyTo: false,
        memo: memo.isNotEmpty ? memo : null,
      );

      recipients.add(Recipient(builder.toBytes()));
    }

    if (totalAmount > availableBalance) {
      throw Exception('Insufficient balance');
    }

    final fee = FeeT(
      fee: internalCalculateEstimatedFee(creds.priority, null),
      minFee: 0,
      maxFee: 0,
      scheme: 0, // Fixed fee scheme
    );

    // pools parameter: bitmask for which pools to use for sending
    // 1=Transparent, 2=Sapling, 4=Orchard, 7=All pools
    // Using 7 (all pools) allows spending from any pool type
    final txPlan = await ZcashWalletService.runInDbMutex(
      () => WarpApi.prepareTx(
        coin,
        accountId,
        recipients,
        7, // pools: All pools (Transparent + Sapling + Orchard) - allows spending from any pool
        1, // senderUAType: 0 = unified address
        0, // anchorOffset
        fee,
      ),
    );

    return PendingZcashTransaction(
      zcashWallet: this as ZcashWallet,
      credentials: creds,
      txPlan: txPlan,
      fee: internalCalculateEstimatedFee(creds.priority, null),
    );
  }

  static const _dispPhrase = "Received to disposable address";
  Future<List<ShieldedTx>> getShieldTxForUi() async {
    final tx = (ZcashTaddressRotation.shieldedAccountsTx[accountId] ?? <ShieldedTx>[])
        .map((final v) {
          final unpacked = v.unpack();
          unpacked.memo ??= "";
          unpacked.memo = "${unpacked.memo}\n$_dispPhrase".trim();
          final List<int> buff = base64.decode(
            ZcashTaddressRotation.flatBuffersPack(unpacked.pack),
          );
          return ShieldedTx(buff);
        })
        .where((final t) => t.value > 0);

    return tx.toList();
  }

  static Map<int, List<ShieldedTx>> temporarySentTx = {};

  static String txChecksumKey(final ShieldedTx tx) {
    final direction = tx.value > 0 ? TransactionDirection.incoming : TransactionDirection.outgoing;
    return 'tx${direction}_${tx.id}_${tx.timestamp}_${CRC32.compute(tx.toString())}';
  }

  @override
  Future<Map<String, ZcashTransactionInfo>> fetchTransactions() async {
    await ZcashWalletService.loadShieldTxs();
    final txs = (await ZcashWalletService.runInDbMutex(
      () => WarpApi.getTxs(coin, accountId),
    )).toList();
    // ShieldedTx{id: 26, txId: 4d1be06ce2c2debec8d98ce4e9434c8aac27c980488b459017d423fdcab37f93, height: 3195705, shortTxId: 4d1be06c, timestamp: 1767730944, name: null, value: 1000000, address: null, memo: , messages: MemoVec{memos: null}}

    final shieldTx = await getShieldTxForUi();

    txs.addAll(shieldTx);
    final txIds = txs.map((final tx) => tx.txId!.replaceAll('"', '')).toSet();
    temporarySentTx[accountId]?.removeWhere(
      (final ttx) => txIds.contains(ttx.txId!.replaceAll('"', '')),
    );
    txs.addAll(temporarySentTx[accountId] ?? []);

    txs.sort((final a, final b) => a.height.compareTo(b.height));
    final Map<String, ZcashTransactionInfo> result = {};
    int currentHeight = 0;
    try {
      currentHeight = await WarpApi.getLatestHeight(coin);
    } catch (e) {
      printV("Error getting latest height: $e");
    }

    for (final tx in txs) {
      final direction = tx.value > 0
          ? TransactionDirection.incoming
          : TransactionDirection.outgoing;

      final confirmations = tx.height > 0 && currentHeight > 0 ? currentHeight - tx.height + 1 : 0;

      final txChecksum = txChecksumKey(tx);
      final txId = tx.txId ?? tx.shortTxId ?? txChecksum;

      final txInfo = ZcashTransactionInfo(
        id: txId.trim().replaceAll('"', ''),
        amount: tx.value.abs(),
        fee: 0,
        direction: direction,
        isPending: tx.height == 0,
        date: DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000),
        height: tx.height,
        confirmations: confirmations,
        to: tx.address ?? '',
        memo: tx.memo,
      );
      // if (txInfo.additionalInfo['autoShield'] == true) {
      //   continue;
      // }
      result[txChecksum] = txInfo;
    }

    return result;
  }

  @override
  Object get keys => {};

  @override
  String get password => _password!;

  @override
  Future<void> renameWalletFiles(final String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: name, type: type);
    final currentCacheFile = File(currentWalletPath);
    final newWalletPath = await pathForWallet(name: newWalletName, type: type);
    if (currentCacheFile.existsSync()) {
      await currentCacheFile.copy(newWalletPath);
    }
    Directory(currentWalletPath).deleteSync(recursive: true);
  }

  @override
  bool get hasRescan => true;

  @override
  @action
  Future<void> rescan({required final int height}) async {
    try {
      syncStatus = StartingScanSyncStatus(height);
      await ZcashWalletService.runInDbMutex(() async => WarpApi.rescanFrom(coin, height));
      await startSync();
    } catch (e) {
      printV("Rescan error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    }
  }

  bool _isTransactionUpdating = false;

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();

      final currentIds = transactionHistory.transactions.keys.toSet();
      final newIds = transactions.keys.toSet();

      currentIds
          .difference(newIds)
          .forEach((final id) => transactionHistory.transactions.remove(id));

      transactions.forEach((final key, final tx) {
        transactionHistory.transactions[key] = tx;
      });
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e, stackTrace) {
      printV("Update transactions error: $e");
      printV("Stack trace: $stackTrace");
      _isTransactionUpdating = false;
    }
  }

  Future<void> updateTransactionsHistory() => updateTransactions();

  @override
  Future<void> save() async {}

  Future<void> init() async {
    try {
      await walletAddresses.init();

      await updateBalance();
      await updateTransactions();
    } catch (e) {
      printV("Wallet init error: $e");
    }
  }

  @override
  String? get seed {
    try {
      final backup = WarpApi.getBackup(coin, accountId);
      final seed = backup.seed!.split(" ");
      if ([13, 25].contains(seed.length)) {
        seed.removeLast();
      }
      return seed.join(" ").trim();
    } catch (e) {
      return null;
    }
  }

  @override
  String? get passphrase {
    try {
      final backup = WarpApi.getBackup(coin, accountId);
      final seed = backup.seed!.split(" ");
      if ([13, 25].contains(seed.length)) {
        final passphrase = seed.removeLast();
        return passphrase;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> signMessage(final String message, {final String? address = null}) {
    throw UnimplementedError();
  }

  @override
  @action
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      _initialSyncHeight = 0;
      _lastKnownBlockHeight = 0;

      _startSyncStatusUpdates();

      syncStatus = SyncronizingSyncStatus();

      unawaited(
        _runWarpSync().catchError((final e) {
          isNodeWorking = false;
          printV("WarpSync error in startSync: $e");
          syncStatus = FailedSyncStatus(error: e.toString());
          _stopSyncStatusUpdates();
        }),
      );
    } catch (e) {
      isNodeWorking = false;
      printV("Sync error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      _stopSyncStatusUpdates();
      rethrow;
    }
  }

  static Mutex warpSyncMutex = Mutex();

  static Future<void> initialSyncCheck() async {
    final zcashDir = await pathForWalletTypeDir(type: WalletType.zcash);
    final zcashInitialSync = File(p.join(zcashDir, ".initial-sync-marker"));
    if (!zcashInitialSync.existsSync()) {
      int chainHeight = 3000000; // fallback if node is offline
      try {
        chainHeight = await WarpApi.getLatestHeight(coin);
      } catch (e) {
        printV("Error getting latest height: $e");
      }
      await ZcashWalletService.runInDbMutex(
        () async => await WarpApi.rescanFrom(coin, chainHeight - 150000),
      );
      zcashInitialSync.writeAsBytesSync([0x00]);
      zcashInitialSync.writeAsStringSync(chainHeight.toString(), mode: FileMode.writeOnlyAppend);
    }
  }

  @action
  Future<void> _runWarpSync() async {
    Timer? _t;
    try {
      await warpSyncMutex.acquire();
      await initialSyncCheck();
      isNodeWorking = true;
      printV("Starting warpSync for coin $coin, account $accountId");
      int? initialQueue = null;
      void _cancelSyncIfShould(final Timer t) {
        initialQueue ??= ZcashWalletService.dbMutexQueue + 2;
        if (ZcashWalletService.dbMutexQueue <= initialQueue!) {
          initialQueue = ZcashWalletService.dbMutexQueue;
          return;
        }
        printV(
          "Canceling sync! (ZcashWalletService.dbMutexQueue: ${ZcashWalletService.dbMutexQueue} > initialQueue: ${initialQueue})",
        );
        WarpApi.cancelSync();
        t.cancel();
        _t = null;
      }

      unawaited(
        Future.delayed(Duration(seconds: 2)).then((_) {
          _t = Timer.periodic(Duration(milliseconds: 100), _cancelSyncIfShould);
        }),
      );
      final result = await ZcashWalletService.runInDbMutex(
        () => WarpApi.warpSync(coin, accountId, true, 0, 100000, 0),
      );
      printV("warpSync completed with result: $result");

      await _updateSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus(error: e.toString());
      unawaited(Future.delayed(Duration(seconds: 1)).then((_) => unawaited(_runWarpSync())));
      _stopSyncStatusUpdates();
    } finally {
      isNodeWorking = false;
      warpSyncMutex.release();
      _t?.cancel();
    }
  }

  void _startSyncStatusUpdates() {
    _stopSyncStatusUpdates();
    _updateSyncStatus();
    _syncStatusTimer = Timer.periodic(const Duration(milliseconds: 5000), (_) {
      _updateSyncStatus().catchError((final e) {
        printV("Error in sync status update timer: $e");
      });
    });
  }

  void _stopSyncStatusUpdates() {
    _syncStatusTimer?.cancel();
    _syncStatusTimer = null;
  }

  void _startPeriodicSync() {
    printV("_startPeriodicSync");
    _stopPeriodicSync();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final chainHeight = await WarpApi.getLatestHeight(coin);
        final dbHeight = WarpApi.getDbHeight(coin);
        final height = dbHeight.unpack();
        final syncHeight = height.height;

        if (syncHeight < chainHeight) {
          printV("Periodic sync: chainHeight=$chainHeight, syncHeight=$syncHeight, starting sync");
          await _runWarpSync();
        } else {
          await updateBalance();
          await updateTransactions();
        }
      } catch (e) {
        printV("Periodic sync error: $e");
      }
    });
  }

  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  @action
  Future<void> _updateSyncStatus() async {
    try {
      final dbHeight = WarpApi.getDbHeight(coin);
      final height = dbHeight.unpack();
      final syncHeight = height.height;

      final chainHeight = await WarpApi.getLatestHeight(coin);

      if (_initialSyncHeight <= 0 && syncHeight > 0) {
        _initialSyncHeight = syncHeight;
        printV("Initialized sync height to: $_initialSyncHeight");
        if (syncHeight - 10 > dbHeight.height) {}
      }

      if (chainHeight <= 0) {
        if (syncStatus is! ConnectedSyncStatus && syncStatus is! ConnectingSyncStatus) {
          syncStatus = ConnectedSyncStatus();
        }
        try {
          await updateBalance();
          await updateTransactions();
        } catch (e) {
          printV("Error updating balance/transactions: $e");
        }
        return;
      }

      if (syncHeight <= 0) {
        if (syncStatus is! ConnectedSyncStatus &&
            syncStatus is! ConnectingSyncStatus &&
            syncStatus is! AttemptingSyncStatus) {
          syncStatus = ConnectedSyncStatus();
        }
        try {
          await updateBalance();
          await updateTransactions();
        } catch (e) {
          printV("Error updating balance/transactions: $e");
        }
        return;
      }

      if (syncHeight >= chainHeight && syncHeight > 0) {
        syncStatus = SyncedSyncStatus();
        _stopSyncStatusUpdates();
        await updateBalance();
        await updateTransactions();
        _startPeriodicSync();
        return;
      }

      if (_lastKnownBlockHeight != syncHeight) {
        _lastKnownBlockHeight = syncHeight;
      }

      if (syncHeight < 0 || chainHeight < syncHeight) {
        return;
      }

      final blocksLeft = chainHeight - syncHeight;
      if (blocksLeft <= 0) {
        syncStatus = SyncedSyncStatus();
        _stopSyncStatusUpdates();
        await updateBalance();
        await updateTransactions();
        _startPeriodicSync();
        return;
      }

      double ptc = 0.0;
      if (_initialSyncHeight > 0) {
        final track = chainHeight - _initialSyncHeight;
        final diff = track > 0 ? track - (chainHeight - syncHeight) : 0;
        ptc = track > 0 && diff >= 0 ? diff / track : 0.0;
      } else {
        ptc = syncHeight / chainHeight;
      }

      syncStatus = SyncingSyncStatus(blocksLeft, ptc.clamp(0.0, 1.0));

      await updateBalance();
      await updateTransactions();
    } catch (e) {
      printV("Sync status update error: $e");
    }
  }

  String getDiversifiedAddress(final int uaType, {final DateTime? time}) {
    try {
      final timestamp = (time ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
      return WarpApi.getDiversifiedAddress(coin, accountId, uaType, timestamp);
    } catch (e) {
      printV("Error getting diversified address: $e");
      return "";
    }
  }

  static final autoShieldMutex = Mutex();
  Future<void> _autoShield() async {
    try {
      await autoShieldMutex.acquire();
      await _$autoShield();
    } catch (e) {
      printV("shielding failed: $e");
      await Future.delayed(Duration(seconds: 30));
    } finally {
      autoShieldMutex.release();
    }
  }

  Future<void> _$autoShield() async {
    final chainHeight = await WarpApi.getLatestHeight(coin);
    final dbHeight = WarpApi.getDbHeight(coin);
    final height = dbHeight.unpack();
    final syncHeight = height.height;
    if (chainHeight != syncHeight) {
      printV("Not autoshielding: chainHeight(${chainHeight}) != syncHeight(${syncHeight})");
      return;
    }
    final bpConfirmed = WarpApi.getPoolBalances(coin, accountId, 0, false);
    if (bpConfirmed.transparent + bpConfirmed.sapling <= 20000) {
      return;
    }

    final recipientBuilder = RecipientObjectBuilder(
      address: (walletAddresses as ZcashWalletAddresses).orchardAddress,
      pools: 4,
      feeIncluded: true,
      amount: bpConfirmed.transparent + bpConfirmed.sapling,
    );

    final recipient = Recipient(recipientBuilder.toBytes());
    final fee = FeeT(fee: 10000, minFee: 0, maxFee: 0, scheme: 0);
    final txPlan = await ZcashWalletService.runInDbMutex(
      () => WarpApi.prepareTx(
        coin,
        accountId,
        [recipient],
        3, // pools: (Transparent + Sapling)
        1,
        0, // anchorOffset
        fee,
      ),
    );
    final _txId = await ZcashWalletService.runInDbMutex(
      () => WarpApi.signAndBroadcast(ZcashWalletBase.coin, accountId, txPlan),
    );
    await ZcashWalletService.addShieldedTx(_txId);
    printV("shielded: $_txId");
    await updateTransactions();
    await updateBalance();
    await Future.delayed(Duration(seconds: 75 * 5)); // do not re-try doing that
  }

  @override
  @action
  Future<void> updateBalance() async {
    try {
      final poolBalances = WarpApi.getPoolBalances(coin, accountId, 0, true);
      final balances = poolBalances.unpack();
      // final notes = WarpApi.getNotesSync(coin, accountId);
      // int frozenBalance = 0;
      // for (final note in notes) {
      //   if (note.excluded) {
      //     frozenBalance += note.value;
      //   }
      // }
      final total = balances.orchard + balances.sapling + balances.transparent;
      final spendable = total - balances.transparent;

      final confirmedPoolBalances = WarpApi.getPoolBalances(coin, accountId, 3, true);
      final confirmedBalances = confirmedPoolBalances.unpack();
      final confirmedTotal =
          confirmedBalances.orchard + confirmedBalances.sapling + confirmedBalances.transparent;
      final confirmedSpendable = confirmedTotal - balances.transparent;

      unawaited(_autoShield());

      balance[CryptoCurrency.zec] = ZcashBalance(
        confirmed: confirmedSpendable,
        unconfirmed: spendable - confirmedSpendable,
        frozen: 0,
      );
    } catch (e, stackTrace) {
      printV("Balance update error: $e");
      printV("Stack trace: $stackTrace");
    }
  }

  @override
  Future<bool> verifyMessage(
    final String message,
    final String signature, {
    final String? address = null,
  }) {
    throw UnimplementedError();
  }

  @observable
  late WalletAddresses walletAddresses = ZcashWalletAddresses(accountId, walletInfo);

  static Future<ZcashWallet> create(final WalletCredentials credentials) async {
    await _init();
    final newWalletCredentials = credentials as ZcashNewWalletCredentials;

    String mnemonic;
    if (newWalletCredentials.mnemonic != null && newWalletCredentials.mnemonic!.isNotEmpty) {
      mnemonic = newWalletCredentials.mnemonic!;
    } else {
      final strength = (newWalletCredentials.seedPhraseLength == 24) ? 256 : 128;
      mnemonic = bip39.generateMnemonic(strength: strength);
    }

    final accountId = await _restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: mnemonic,
      passphrase: newWalletCredentials.passphrase,
    );
    await _saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.walletAddresses.saveAddressesInBox();
    return wallet;
  }

  static Future<ZcashWallet> restore(final WalletCredentials credentials) async {
    await _init();
    final fromSeedCredentials = credentials as ZcashFromSeedWalletCredentials;
    final String? seed = fromSeedCredentials.seed;
    if (seed == null || seed.isEmpty) {
      throw Exception('Seed phrase is required for wallet restoration');
    }

    final accountId = await _restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: seed,
      passphrase: fromSeedCredentials.passphrase,
    );
    await _saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.walletAddresses.saveAddressesInBox();
    return wallet;
  }

  static Future<ZcashWallet> open({
    required final String name,
    required final String password,
    required final WalletInfo walletInfo,
  }) async {
    await _init();
    if (password.isNotEmpty) {
      WarpApi.setDbPasswd(coin, password);
    }
    final accountId = await getZcashAccountIdForName(name);
    if (accountId == null) {
      throw Exception("Wallet account not found for name: $name");
    }
    final wallet = ZcashWallet(
      walletInfo,
      await walletInfo.getDerivationInfo(),
      accountId: accountId,
    );
    await wallet.walletAddresses.init();
    return wallet;
  }

  static Future<int> _restoreZcashWalletFromSeed({
    required final String name,
    required String seed,
    required String? passphrase,
  }) async {
    if (passphrase?.isNotEmpty == true) {
      passphrase = passphrase!.replaceAll(" ", "_");
      seed = "${seed} ${passphrase}";
    }
    final accountId = await ZcashWalletService.runInDbMutex(
      () => WarpApi.newAccount(coin, name, seed, 0),
    );
    return accountId;
  }

  static Future<int?> getZcashAccountIdForName(final String name) async {
    final wPath = await pathForWallet(name: name, type: _type);
    final f = File(wPath);
    if (!f.existsSync()) {
      final accounts = WarpApi.getAccountList(coin);
      for (final account in accounts) {
        if (account.name == name) {
          return account.id;
        }
      }
      return null;
    }
    final content = f.readAsStringSync();
    return int.tryParse(content.trim());
  }

  static Future<void> _saveAccountId(final String name, final int accountId) async {
    final wPath = await pathForWallet(name: name, type: _type);
    final f = File(wPath);
    f.writeAsStringSync(accountId.toString());
  }

  static WalletType get _type => WalletType.zcash;

  static Future<String> getDbDataPath() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final dbDataPath = "${pathForWalletType}/zec.db";
    if (!Directory(pathForWalletType).existsSync()) {
      Directory(pathForWalletType).createSync(recursive: true);
    }
    return dbDataPath;
  }

  static Future<String> getTorDir() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final torPath = "${pathForWalletType}/tor";
    if (!Directory(torPath).existsSync()) {
      Directory(torPath).createSync(recursive: true);
    }
    return torPath;
  }

  static Future<String> getFsBlockCacheDir() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final fsBlockCacheDir = "${pathForWalletType}/blockCache";
    if (!Directory(pathForWalletType).existsSync()) {
      Directory(pathForWalletType).createSync(recursive: true);
    }
    return fsBlockCacheDir;
  }

  static String? dbDataPath;
  static bool _initialized = false;

  static void unlockDatabase(final String password) {
    _password = password;
  }

  static String? _password;
  static Future<void> _init() async {
    if (_initialized) return;
    dbDataPath = await getDbDataPath();
    printV("WarpApi.initWallet");
    if (_password == null) {
      throw Exception("Zcash wallet locked! Please contact support");
    }
    if (!File(dbDataPath!).existsSync()) {
      //TODO(mrcyjanek): copy-encrypt
    }
    WarpApi.setDbPasswd(coin, _password! + ";cw_zcash");
    WarpApi.initWallet(coin, dbDataPath!);
    WarpApi.setDbPasswd(coin, _password! + ";cw_zcash");
    final spend = await rootBundle.load('scripts/zcash_lib/assets/sapling-spend.params');
    final output = await rootBundle.load('scripts/zcash_lib/assets/sapling-output.params');
    WarpApi.initProver(spend.buffer.asUint8List(), output.buffer.asUint8List());
    await ZcashTaddressRotation.init();
    await ZcashTransactionInfo.init();
    _initialized = true;
  }

  static Future<int> getHeightByDate(final DateTime date) {
    return WarpApi.getBlockHeightByTime(coin, date);
  }
}
