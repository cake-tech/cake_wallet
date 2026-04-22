import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/get_height_by_date_zec.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/util/crc32.dart';
import 'package:cw_zcash/src/util/hex.dart';
import 'package:cw_zcash/src/zcash_taddress_rotation.dart';
import 'package:cw_zcash/src/zcash_wallet_addresses.dart';
import 'package:cw_zcash/src/zkooltx.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:mutex/mutex.dart';
import 'package:zkool/src/rust/api/account.dart' as zkool_account;
import 'package:zkool/src/rust/api/coin.dart' as zkool_coin;
import 'package:zkool/src/rust/api/sync.dart' as zkool_sync;
import 'package:zkool/src/rust/api/pay.dart' as zkool_pay;
import 'package:zkool/src/rust/api/network.dart' as zkool_network;
import 'package:zkool/src/rust/pay.dart' as zkool_paydart;
import 'package:zkool/src/rust/frb_generated.dart' as zkool_frb;

part 'zcash_wallet.g.dart';

class ZcashWallet = ZcashWalletBase with _$ZcashWallet;

abstract class ZcashWalletBase
    extends WalletBase<ZcashBalance, ZcashTransactionHistory, ZcashTransactionInfo>
    with Store {
  ZcashWalletBase(super.walletInfo, super.derivationInfo, {required this.accountId}) {
    transactionHistory = ZcashTransactionHistory();
  }

  final int accountId;
  @override
  @observable
  SyncStatus syncStatus = NotConnectedSyncStatus();

  @override
  ObservableMap<CryptoCurrency, ZcashBalance> balance = ObservableMap.of({
    CryptoCurrency.zec: ZcashBalance.zero(),
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
  Future<void> close({final bool shouldCleanup = false}) async {}

  Node? lastNode;
  @override
  @action
  Future<void> connectToNode({required final Node node}) async {
    lastNode = node;
    printV("connecting to node: ${node.uriRaw}");
    syncStatus = ConnectingSyncStatus();
    try {
      String lwdUrl = node.uriRaw;
      if (!lwdUrl.startsWith('http://') && !lwdUrl.startsWith('https://')) {
        final protocol = node.useSSL == true ? 'https://' : 'http://';
        lwdUrl = '$protocol$lwdUrl';
      }
      printV("Setting LWD URL to: $lwdUrl");
      c = c.setLwd(url: lwdUrl, serverType: 0);
      syncStatus = ConnectedSyncStatus();
      unawaited(_runSyncLoop());
    } catch (e) {
      printV("Connection error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    }
  }

  Future<void> _runSyncLoop() async {
    while (true) {
      await Future.delayed(Duration(seconds: 1));
      try {
        await _oneshotSync();
      } catch (e) {
        printV("zcash sync failed: $e");
      }
    }
  }

  static int dbHeight = 0;

  bool isSyncing = false;

  static int oneshotSyncCount = 0;

  @action
  Future<void> _oneshotSync() async {
    try {
      if (isSyncing) return;
      c = await c.setAccount(account: accountId);
      final currentHeight = await zkool_network.getCurrentHeight(c: c);
      await zkool_sync.cancelSync();
      final accounts = await zkool_account.listAccounts(c: c);
      final accountList = accounts.map((final a) => a.id).toList()
        ..removeWhere((final a) => a == c.account);
      c = await c.setAccount(account: accountId);
      final sync = zkool_sync.synchronize(
        accounts: [c.account, ...accountList, c.account],
        currentHeight: currentHeight,
        actionsPerSync: 10000,
        transparentLimit: 100,
        checkpointAge: 200,
        c: c,
        fast: true,
      );
      c = await c.setAccount(account: accountId);
      final randInt = CRC32.compute("${DateTime.now().microsecondsSinceEpoch}").toRadixString(16);
      isSyncing = true;
      oneshotSyncCount++;
      await sync
        ..listen(
          (final syncProgress) {
            unawaited(updateBalance());
            unawaited(updateTransactions());
            printV(
              "[${c.account} ($accountList)] [$oneshotSyncCount/$randInt] sync: ${syncProgress.height}",
            );
            syncStatus = SyncingSyncStatus(
              currentHeight - syncProgress.height,
              (currentHeight - syncProgress.height) / currentHeight,
            );
            dbHeight = syncProgress.height;
          },
          onError: (final e) {
            printV("[${c.account} ($accountList)] [$oneshotSyncCount/$randInt] error syncing: $e");
            syncStatus = FailedSyncStatus(error: e.toString());
            isSyncing = false;
          },
          onDone: () {
            printV("[${c.account} ($accountList)] [$oneshotSyncCount/$randInt] synchronized");
            unawaited(updateBalance());
            unawaited(updateTransactions());
            oneshotSyncCount--;
            syncStatus = SyncedSyncStatus();
            isSyncing = false;
          },
        );
    } catch (e) {
      printV("error syncing: $e");
    }
  }

  @override
  Future<PendingTransaction> createTransaction(final Object credentials) =>
      _createTransaction(credentials);

  Future<PendingTransaction> _createTransaction(
    final Object credentials, {
    final int tryReduceFeeAmount = 0,
  }) async {
    final creds = credentials as ZcashTransactionCredentials;
    await updateBalance();

    final zcashBalance = balance[CryptoCurrency.zec];
    final availableBalance = zcashBalance?.available ?? Money.zero(currency);

    final recipients = <zkool_paydart.Recipient>[];

    bool receipientPaysFee = false;

    for (final output in creds.outputs) {
      receipientPaysFee = receipientPaysFee || output.sendAll;
      var amount = output.cryptoAmount;
      if (output.sendAll) {
        amount = availableBalance - Money.fromInt(tryReduceFeeAmount, currency);
      }
      recipients.add(
        zkool_paydart.Recipient(address: output.address, amount: amount.amount, userMemo: output.memo),
      );
    }

    final sendAmount = creds.outputs
        .map((final out) => out.cryptoAmount)
        .reduce((final a, final b) => a + b);

    if (availableBalance == sendAmount) {
      receipientPaysFee = true;
    }

    // pools parameter: bitmask for which pools to use for sending
    // 1=Transparent, 2=Sapling, 4=Orchard, 7=All pools
    // Using 7 (all pools) allows spending from any pool type
    try {
      final txPlan = await zkool_pay.prepare(
        recipients: recipients,
        options: zkool_pay.PaymentOptions(
          srcPools: 7,
          recipientPaysFee: receipientPaysFee,
          smartTransparent: false,
        ),
        c: c,
      );
      return PendingZcashTransaction(
        zcashWallet: this as ZcashWallet,
        credentials: creds,
        txPlan: txPlan,
        fee: Money.fromInt(
          tryReduceFeeAmount != 0
              ? tryReduceFeeAmount
              : internalCalculateEstimatedFee(creds.priority, null),
          currency,
        ),
        availableBalance: availableBalance,
      );
    } catch (e) {
      if (tryReduceFeeAmount != 0) rethrow;
      final estr = e.toString();
      const prefix = "Not enough funds, ";
      const suffix = " more ZEC required";
      if (estr.contains(prefix) && estr.contains(suffix)) {
        final start = estr.indexOf(prefix) + prefix.length;
        final end = estr.indexOf(suffix, start);
        final amtStr = estr.substring(start, end);
        final amt = double.tryParse(amtStr);
        if (amt == null) rethrow;
        final feeInt = (amt * 100000000).ceil();
        return _createTransaction(credentials, tryReduceFeeAmount: feeInt);
      }
      rethrow;
    }
  }

  static const _dispPhrase = "Received to disposable address";
  Future<List<dynamic>> getShieldTxForUi() async {
    final tx = (ZcashTaddressRotation.shieldedAccountsTx[accountId] ?? <dynamic>[])
        .map((final v) {
          final unpacked = v.unpack();
          unpacked.memo = "${unpacked.memo ?? ''}\n$_dispPhrase".trim();
          return unpacked;
        })
        .where((final t) => t.value > 0);

    return tx.toList();
  }

  static String txChecksumKey(final ZkoolTx tx) {
    return 'tx${tx.direction}_${tx.txHash}_${tx.time}_${CRC32.compute(tx.toString())}';
  }

  @override
  Future<Map<String, ZcashTransactionInfo>> fetchTransactions() async {
    // await ZcashWalletService.loadShieldTxs();
    // await ZcashWalletService.runInDbMutex(() => refreshAccountCache(coin, accountId));
    // await ZcashWalletService.runInDbMutex(() => refreshTxsCache(coin, accountId));
    c = await c.setAccount(account: accountId);
    final txsI = await zkool_account.listTxHistory(c: c);
    final txsA = await Future.wait(
      txsI.map((final tx) => zkool_account.getTxDetails(idTx: tx.id, c: c)),
    );
    final txs = <ZkoolTx>[];
    for (int i = 0; i < txsI.length; i++) {
      txs.add(ZkoolTx(txsI[i], txsA[i]));
    }
    // final txs = getCachedTxs(coin, accountId).toList();
    // ShieldedTx{id: 26, txId: 4d1be06ce2c2debec8d98ce4e9434c8aac27c980488b459017d423fdcab37f93, height: 3195705, shortTxId: 4d1be06c, timestamp: 1767730944, name: null, value: 1000000, address: null, memo: , messages: MemoVec{memos: null}}
    // final shieldTx = await getShieldTxForUi();

    // final txIds = txs.map((final tx) => tx.txId!.replaceAll('"', '')).toSet();
    // temporarySentTx[accountId]?.removeWhere(
    //   (final ttx) => txIds.contains(ttx.txId!.replaceAll('"', '')),
    // );
    // txs.addAll(temporarySentTx[accountId] ?? []);

    txs.sort((final a, final b) => a.height.compareTo(b.height));
    final Map<String, ZcashTransactionInfo> result = {};
    int currentHeight = 1;
    try {
      currentHeight = await zkool_network.getCurrentHeight(c: ZcashWalletBase.c);
    } catch (e) {
      printV("failed to get height: $e");
    }
    for (final tx in txs) {
      final confirmations = tx.height > 0 && currentHeight > 0 ? currentHeight - tx.height + 1 : 0;
      final txChecksum = txChecksumKey(tx);

      final txInfo = ZcashTransactionInfo(
        id: tx.txHash,
        amount: Money(tx.value, currency),
        fee: Money.zero(currency),
        direction: tx.direction,
        isPending: tx.height == 0,
        date: tx.time,
        height: tx.height,
        confirmations: confirmations,
        to: tx.to ?? "",
        memo: tx.memo,
      );

      if (txInfo.additionalInfo['autoShield'] == true) {
        continue;
      }
      result[txChecksum] = txInfo;
    }

    return result;
  }

  Future<void> _initKeys() async {
    try {
      c = await c.setAccount(account: accountId);
      final ufvk = await zkool_account.getAccountUfvk(account: accountId, c: c, pools: 7);

      keys = {
        "privateViewKey": ufvk,
        if (lastKnownRestoreHeight != null) "restoreHeight": lastKnownRestoreHeight.toString(),
      };
    } catch (e) {
      keys = {"privateViewKey": e.toString()};
    }
    try {
      c = await c.setAccount(account: accountId);
      final s = (await zkool_account.getAccountSeed(account: accountId, c: c));

      if (s == null) {
        throw Exception("seed not found");
      }
      final seedPhrase = s.mnemonic.split(" ");
      if ([13, 25].contains(seedPhrase.length)) {
        passphrase = seedPhrase.removeLast();
      } else {
        passphrase = s.phrase;
      }
      seed = s.mnemonic.trim();
    } catch (e) {
      seed = e.toString();
    }
  }

  @override
  Object keys = {};

  @override
  String get password => _password!;

  @override
  Future<void> renameWalletFiles(final String newWalletName) async {
    final legacyWalletPath = await pathForWallet(name: name, type: type);
    final legacyWalletFile = File(legacyWalletPath);
    final currentWalletFile = File(legacyWalletPath + ".v2");
    final newLegacyWalletPath = await pathForWallet(name: newWalletName, type: type);
    if (legacyWalletFile.existsSync()) {
      await legacyWalletFile.copy(newLegacyWalletPath);
    }
    if (currentWalletFile.existsSync()) {
      await currentWalletFile.copy(newLegacyWalletPath + ".v2");
    }
    Directory(legacyWalletPath).deleteSync(recursive: true);
  }

  @override
  bool get hasRescan => false;

  static int? lastKnownRestoreHeight = null;

  static int zashiAnnouncedBlockHeight = 2419420;

  @override
  @action
  Future<void> rescan({required final int height}) async {
    try {
      syncStatus = StartingScanSyncStatus(height);
      printV("rescanning from: $height");
    } catch (e) {
      printV("Rescan error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
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

  @override
  Future<void> save() async {}

  Future<void> init() async {
    try {
      await walletAddresses.init();

      await updateBalance();
      await updateTransactions();
      await ZcashTaddressRotation.init();
      await _initKeys();
    } catch (e) {
      printV("Wallet init error: $e");
    }
  }

  @override
  String? seed = "";

  @override
  String? passphrase = "";

  @override
  Future<String> signMessage(final String message, {final String? address = null}) {
    throw UnimplementedError();
  }

  @override
  @action
  Future<void> startSync() async {
    if (syncStatus is AttemptingSyncStatus ||
        syncStatus is SyncronizingSyncStatus ||
        syncStatus is SyncingSyncStatus ||
        syncStatus is SyncedSyncStatus) {
      return;
    }
    try {
      syncStatus = AttemptingSyncStatus();
    } catch (e) {
      isNodeWorking = false;
      printV("Sync error: $e");
      syncStatus = FailedSyncStatus(error: e.toString());
      rethrow;
    }
  }

  static Mutex warpSyncMutex = Mutex();

  static final autoShieldMutex = Mutex();
  static late final appStartTime = DateTime.now();
  Future<void> _autoShield() async {
    // let the app breethe
    if (appStartTime.isBefore(DateTime.now().subtract(Duration(seconds: 25)))) {
      return;
    }
    try {
      await autoShieldMutex.acquire();
      await _$autoShield();
    } catch (e, s) {
      printV("shielding failed: $e");
      s.toString().split("\n").forEach(printV);
    } finally {
      autoShieldMutex.release();
    }
  }

  Future<void> _$autoShield() async {
    if (syncStatus is SyncedSyncStatus) {
      printV("Not autoshielding: [$syncStatus !is SyncedSyncStatus]");
      return;
    }
    c = await c.setAccount(account: accountId);
    final _notes = await zkool_account.listNotes(c: c);
    final List<zkool_account.TxNote> txNotes = [];
    for (int i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      final noteType = NotePool.values[note.pool];
      if ([NotePool.sapling, NotePool.transparent].contains(noteType)) {
        txNotes.add(note);
      }
    }

    final sweepable = txNotes.isEmpty
        ? BigInt.from(0)
        : txNotes.map((final txn) => txn.value).reduce((final a, final b) => a + b);

    if (sweepable <= BigInt.from(20000)) {
      return;
    }

    final txPlan = await zkool_pay.prepare(
      recipients: [
        zkool_paydart.Recipient(address: walletAddresses.orchardAddress!, amount: sweepable),
      ],
      options: zkool_pay.PaymentOptions(
        srcPools: 7,
        recipientPaysFee: true,
        smartTransparent: false,
      ),
      c: c,
    );

    final signTx = await zkool_pay.signTransaction(pczt: txPlan, c: ZcashWalletBase.c);
    final txBytes = await zkool_pay.extractTransaction(package: signTx);
    final currentHeight = await zkool_network.getCurrentHeight(c: ZcashWalletBase.c);
    final _txId = await zkool_pay.broadcastTransaction(
      height: currentHeight,
      txBytes: txBytes,
      c: ZcashWalletBase.c,
    );

    await ZcashWalletService.addShieldedTx(_txId);
    printV("shielded: $_txId");
    await updateTransactions();
    await updateBalance();
    await Future.delayed(Duration(seconds: 75)); // do not re-try doing that
  }

  @override
  @action
  Future<void> updateBalance() async {
    try {
      c = await c.setAccount(account: accountId);

      final bal = await zkool_sync.balance(c: c);

      // 0 - transparent
      // 1 - sapling
      // 2 - orchard
      final confirmedTotal = bal.field0.reduce((final a, final b) => a + b);

      // int knownOutPending = 0;
      // ZcashWalletBase.temporarySentTx[accountId]?.forEach((final sTx) {
      //   knownOutPending += sTx.value; // it's negative
      // });
      final confirmedSpendable = confirmedTotal - bal.field0[0];

      await _autoShield();

      balance[CryptoCurrency.zec] = ZcashBalance(
        Money(confirmedSpendable, currency),
        Money(confirmedTotal - confirmedSpendable, currency),
        frozen: Money.zero(currency),
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

  @override
  late final ZcashWalletAddresses walletAddresses = ZcashWalletAddresses(accountId, walletInfo);

  static Future<ZcashWallet> create(final WalletCredentials credentials) async {
    await $init();
    final newWalletCredentials = credentials as ZcashNewWalletCredentials;

    String mnemonic;
    if (newWalletCredentials.mnemonic?.isNotEmpty == true) {
      mnemonic = newWalletCredentials.mnemonic!;
    } else {
      final strength = (newWalletCredentials.seedPhraseLength == 24) ? 256 : 128;
      mnemonic = bip39.generateMnemonic(strength: strength);
    }

    final birthHeight = await ZcashHeight.getBlockHeightByTime(DateTime.now());

    final accountId = await restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: mnemonic,
      passphrase: newWalletCredentials.passphrase,
      birthHeight: birthHeight,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.walletAddresses.saveAddressesInBox();
    return wallet;
  }

  static Future<ZcashWallet> restore(final WalletCredentials credentials) async {
    await $init();
    final fromSeedCredentials = credentials as ZcashFromSeedWalletCredentials;
    final String? seed = fromSeedCredentials.seed;
    if (seed == null || seed.isEmpty) {
      throw Exception('Seed phrase is required for wallet restoration');
    }

    final accountId = await restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: seed,
      passphrase: fromSeedCredentials.passphrase,
      birthHeight: credentials.height!,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.walletAddresses.saveAddressesInBox();
    return wallet;
  }

  static Future<ZcashWallet> restoreKeys(final WalletCredentials credentials) async {
    await $init();
    final fromKeysCredentials = credentials as ZcashFromKeysWalletCredentials;
    final String? keys = fromKeysCredentials.privateKey;
    if (keys == null || keys.isEmpty) {
      throw Exception('Key is required for wallet restoration');
    }

    final zcashSecretExtendedKeyRegex = RegExp(r'^secret-extended-key-main1[a-z0-9]+$');
    if (!zcashSecretExtendedKeyRegex.hasMatch(keys)) {
      throw Exception('Key is not in secret-extended-key-main1 format');
    }

    final accountId = await restoreZcashWalletFromSeed(
      name: credentials.name,
      seed: keys,
      passphrase: fromKeysCredentials.passphrase,
      birthHeight: credentials.height!,
    );
    await saveAccountId(credentials.name, accountId);
    final wallet = await open(
      name: credentials.name,
      password: credentials.password!,
      walletInfo: credentials.walletInfo!,
    );
    await wallet.walletAddresses.saveAddressesInBox();
    printV("height: ${credentials.height}");
    return wallet;
  }

  static Future<ZcashWallet> open({
    required final String name,
    required final String password,
    required final WalletInfo walletInfo,
  }) async {
    await $init();
    // if (password.isNotEmpty) {
    //   setDbPasswd(coin, password);
    // }
    final accountId = await getZcashAccountIdForName(name);
    if (accountId == null) {
      throw Exception("accountId is null");
    }
    c = await c.setAccount(account: accountId);
    if (accountId == null) {
      throw Exception("Wallet account not found for name: $name");
    }
    final wallet = ZcashWallet(
      walletInfo,
      await walletInfo.getDerivationInfo(),
      accountId: accountId,
    );
    await wallet.walletAddresses.init();
    await wallet._initKeys();
    return wallet;
  }

  static Future<int> restoreZcashWalletFromSeed({
    required final String name,
    required final String seed,
    required final String? passphrase,
    required final int birthHeight,
  }) async {
    // if (passphrase?.isNotEmpty == true) {
    //   passphrase = passphrase!.replaceAll(" ", "_");
    //   seed = "${seed} ${passphrase}";
    // }

    final accountId = await newAccount(
      name: name,
      height: birthHeight,
      seed: seed,
      passphrase: passphrase ?? '',
    );
    return accountId;
  }

  static Future<int?> getLegacyZcashAccountIdForName(final String name) async {
    final wPath = (await pathForWallet(name: name, type: _type));
    final f = File(wPath);
    if (!f.existsSync()) {
      final accs = await zkool_account.listAccounts(c: c);
      for (final acc in accs) {
        if (acc.name == name) {
          return acc.id;
        }
      }
    }
    final content = f.readAsStringSync();
    return int.tryParse(content.trim());
  }

  static Future<int?> getZcashAccountIdForName(final String name) async {
    final wPath = (await pathForWallet(name: name, type: _type)) + ".v2";
    final f = File(wPath);
    if (!f.existsSync()) {
      final accs = await zkool_account.listAccounts(c: c);
      for (final acc in accs) {
        if (acc.name == name) {
          return acc.id;
        }
      }
    }
    final content = f.readAsStringSync();
    return int.tryParse(content.trim());
  }

  static Future<void> saveAccountId(final String name, final int accountId) async {
    final wPath = (await pathForWallet(name: name, type: _type)) + ".v2";
    final dirName = Directory(wPath).parent.path;
    if (!Directory(dirName).existsSync()) {
      Directory(dirName).createSync(recursive: true);
    }
    final f = File(wPath);
    f.writeAsStringSync(accountId.toString());
  }

  static WalletType get _type => WalletType.zcash;

  static Future<String> getDbDataPath() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final dbDataPath = "${pathForWalletType}/zec.v2.db";
    if (!Directory(pathForWalletType).existsSync()) {
      Directory(pathForWalletType).createSync(recursive: true);
    }
    return dbDataPath;
  }

  static Future<String> getDbDataPathLegacyYwallet() async {
    final pathForWalletType = await pathForWalletTypeDir(type: _type);
    final dbDataPath = "${pathForWalletType}/zec.db";
    if (!Directory(pathForWalletType).existsSync()) {
      Directory(pathForWalletType).createSync(recursive: true);
    }
    return dbDataPath;
  }

  static bool _initialized = false;

  static void unlockDatabase(final String password) {
    _password = password;
  }

  static var c = zkool_coin.Coin();

  static String? _password;
  static Future<void> $init() async {
    if (_initialized) return;
    _initialized = true;
    printV(r".$init()");
    await zkool_frb.RustLib.init();
    final dbFile = File(await getDbDataPath());
    final ywalletDbFile = File(await getDbDataPathLegacyYwallet());
    await zkool_network.initDatadir(directory: dbFile.parent.path);
    // c = await c.openDatabase(dbFilepath: dbFile.path, password: 'cw_zcash_migration');
    c = await c.openDatabase(dbFilepath: dbFile.path, password: null);
    printV("initWallet");
    if (_password == null) {
      throw Exception("Zcash wallet locked! Please contact support");
    }
    if (!dbFile.existsSync()) {
      //TODO(mrcyjanek): copy-encrypt
    }
    if (!ywalletDbFile.existsSync()) {
      //TODO(mrcyjanek): migrate to zkool
    }

    _initialized = true;
  }

  static Future<int> getHeightByDate(final DateTime date) async {
    final height = await ZcashHeight.getBlockHeightByTime(date);
    return height;
  }

  static Future<int> newAccount({
    required final String name,
    required final int height,
    required final String seed,
    required final String passphrase,
  }) async {
    final id = await zkool_account.newAccount(
      na: zkool_account.NewAccount(
        name: name,
        restore: true,
        passphrase: passphrase,
        key: seed,
        aindex: 0,
        birth: height,
        folder: '',
        useInternal: true,
        internal: true,
        ledger: false,
      ),
      c: c,
    );
    return id;
  }

  static final runWithCoinMutex = Mutex();
  static int runWithCoinCount = 0;
  static FutureOr<T> runWithCoin<T>({
    required final int accountId,
    required final FutureOr<T> Function(zkool_coin.Coin c) func,
  }) async {
    var newC = zkool_coin.Coin();
    newC = await newC.openDatabase(dbFilepath: c.dbFilepath);
    newC = await newC.setAccount(account: accountId);
    newC = await newC.setLwd(serverType: c.serverType, url: c.url);
    newC = await newC.setUseTor(useTor: c.useTor);

    runWithCoinCount++;
    printV("run with coin: $runWithCoinCount");
    // await runWithCoinMutex.acquire();
    // final currentId = c.account;
    try {
      newC = await newC.setAccount(account: accountId);
      return await func(newC);
    } finally {
      // newC = await newC.setAccount(account: currentId);
      // runWithCoinMutex.release();
      runWithCoinCount--;
    }
  }
}
