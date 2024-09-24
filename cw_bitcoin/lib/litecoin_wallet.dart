import 'dart:async';
import 'dart:convert';
import 'package:convert/convert.dart' as convert;
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/mweb_utxo.dart';
import 'package:cw_mweb/mwebd.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/signer/ecdsa_signing_key.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/litecoin_wallet_addresses.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:bitcoin_base/src/crypto/keypair/sign_utils.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';

part 'litecoin_wallet.g.dart';

class LitecoinWallet = LitecoinWalletBase with _$LitecoinWallet;

abstract class LitecoinWalletBase extends ElectrumWallet with Store {
  LitecoinWalletBase({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Uint8List seedBytes,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
    String? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinAddressRecord>? initialMwebAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    int? initialMwebHeight,
    bool? alwaysScan,
  }) : super(
          mnemonic: mnemonic,
          password: password,
          walletInfo: walletInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          network: LitecoinNetwork.mainnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          encryptionFileUtils: encryptionFileUtils,
          currency: CryptoCurrency.ltc,
        ) {
    mwebHd = Bip32Slip10Secp256k1.fromSeed(seedBytes).derivePath("m/1000'") as Bip32Slip10Secp256k1;
    mwebEnabled = alwaysScan ?? false;
    walletAddresses = LitecoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialMwebAddresses: initialMwebAddresses,
      mainHd: hd,
      sideHd: accountHD.childKey(Bip32KeyIndex(1)),
      network: network,
      mwebHd: mwebHd,
      mwebEnabled: mwebEnabled,
    );
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }
  late final Bip32Slip10Secp256k1 mwebHd;
  late final Box<MwebUtxo> mwebUtxosBox;
  Timer? _syncTimer;
  Timer? _feeRatesTimer;
  StreamSubscription<Utxo>? _utxoStream;
  late RpcClient _stub;
  late bool mwebEnabled;

  List<int> get scanSecret => mwebHd.childKey(Bip32KeyIndex(0x80000000)).privateKey.privKey.raw;
  List<int> get spendSecret => mwebHd.childKey(Bip32KeyIndex(0x80000001)).privateKey.privKey.raw;

  static Future<LitecoinWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required EncryptionFileUtils encryptionFileUtils,
      String? passphrase,
      String? addressPageType,
      List<BitcoinAddressRecord>? initialAddresses,
      List<BitcoinAddressRecord>? initialMwebAddresses,
      ElectrumBalance? initialBalance,
      Map<String, int>? initialRegularAddressIndex,
      Map<String, int>? initialChangeAddressIndex}) async {
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
    return LitecoinWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialMwebAddresses: initialMwebAddresses,
      initialBalance: initialBalance,
      encryptionFileUtils: encryptionFileUtils,
      passphrase: passphrase,
      seedBytes: seedBytes,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: addressPageType,
    );
  }

  static Future<LitecoinWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required bool alwaysScan,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);

    ElectrumWalletSnapshot? snp = null;

    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        LitecoinNetwork.mainnet,
      );
    } catch (e) {
      if (!hasKeysFile) rethrow;
    }

    final WalletKeysData keysData;
    // Migrate wallet from the old scheme to then new .keys file scheme
    if (!hasKeysFile) {
      keysData =
          WalletKeysData(mnemonic: snp!.mnemonic, xPub: snp.xpub, passphrase: snp.passphrase);
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
    }

    return LitecoinWallet(
      mnemonic: keysData.mnemonic!,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp?.addresses,
      initialMwebAddresses: snp?.mwebAddresses,
      initialBalance: snp?.balance,
      seedBytes: seedBytes!,
      passphrase: passphrase,
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: snp?.addressPageType,
      alwaysScan: alwaysScan,
    );
  }

  Future<void> waitForMwebAddresses() async {
    // ensure that we have the full 1000 mweb addresses generated before continuing:
    // should no longer be needed, but leaving here just in case
    final mwebAddrs = (walletAddresses as LitecoinWalletAddresses).mwebAddrs;
    while (mwebAddrs.length < 1000) {
      print("waiting for mweb addresses to finish generating...");
      await Future.delayed(const Duration(milliseconds: 1000));
    }
  }

  @action
  @override
  Future<void> startSync() async {
    if (syncStatus is SyncronizingSyncStatus) {
      return;
    }
    print("STARTING SYNC - MWEB ENABLED: $mwebEnabled");
    try {
      syncStatus = SyncronizingSyncStatus();
      await subscribeForUpdates();
      updateFeeRates();
      _feeRatesTimer?.cancel();
      _feeRatesTimer =
          Timer.periodic(const Duration(minutes: 1), (timer) async => await updateFeeRates());

      if (!mwebEnabled) {
        try {
          await updateAllUnspents();
          await updateTransactions();
          await updateBalance();
          syncStatus = SyncedSyncStatus();
        } catch (e, s) {
          print(e);
          print(s);
          syncStatus = FailedSyncStatus();
        }
        return;
      }

      await waitForMwebAddresses();
      await getStub();
      await processMwebUtxos();
      await updateTransactions();
      await updateUnspent();
      await updateBalance();
    } catch (e) {
      print("failed to start mweb sync: $e");
      syncStatus = FailedSyncStatus();
      return;
    }

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (syncStatus is FailedSyncStatus) return;

      final nodeHeight =
          await electrumClient.getCurrentBlockChainTip() ?? 0; // current block height of our node
      final resp = await CwMweb.status(StatusRequest());

      if (resp.blockHeaderHeight < nodeHeight) {
        int h = resp.blockHeaderHeight;
        syncStatus = SyncingSyncStatus(nodeHeight - h, h / nodeHeight);
      } else if (resp.mwebHeaderHeight < nodeHeight) {
        int h = resp.mwebHeaderHeight;
        syncStatus = SyncingSyncStatus(nodeHeight - h, h / nodeHeight);
      } else if (resp.mwebUtxosHeight < nodeHeight) {
        syncStatus = SyncingSyncStatus(1, 0.999);
      } else {
        if (resp.mwebUtxosHeight > walletInfo.restoreHeight) {
          await walletInfo.updateRestoreHeight(resp.mwebUtxosHeight);
          await checkMwebUtxosSpent();
          // update the confirmations for each transaction:
          for (final transaction in transactionHistory.transactions.values) {
            if (transaction.isPending) continue;
            int txHeight = transaction.height ?? resp.mwebUtxosHeight;
            final confirmations = (resp.mwebUtxosHeight - txHeight) + 1;
            if (transaction.confirmations == confirmations) continue;
            transaction.confirmations = confirmations;
            transactionHistory.addOne(transaction);
          }
          await transactionHistory.save();
        }

        // prevent unnecessary reaction triggers:
        if (syncStatus is! SyncedSyncStatus) {
          // mwebd is synced, but we could still be processing incoming utxos (should only take a few seconds)
          // so we wait a few seconds before marking the wallet as synced
          await Future.delayed(const Duration(seconds: 3));
          syncStatus = SyncedSyncStatus();
        }
        return;
      }
    });
  }

  @action
  @override
  Future<void> stopSync() async {
    _syncTimer?.cancel();
    _utxoStream?.cancel();
    _feeRatesTimer?.cancel();
    await CwMweb.stop();
  }

  Future<void> initMwebUtxosBox() async {
    final boxName = "${walletInfo.name.replaceAll(" ", "_")}_${MwebUtxo.boxName}";

    mwebUtxosBox = await CakeHive.openBox<MwebUtxo>(boxName);
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    // rename the hive box:
    final oldBoxName = "${walletInfo.name.replaceAll(" ", "_")}_${MwebUtxo.boxName}";
    final newBoxName = "${newWalletName.replaceAll(" ", "_")}_${MwebUtxo.boxName}";

    final oldBox = await CakeHive.openBox<MwebUtxo>(oldBoxName);
    mwebUtxosBox = await CakeHive.openBox<MwebUtxo>(newBoxName);
    for (final key in oldBox.keys) {
      await mwebUtxosBox.put(key, oldBox.get(key)!);
    }
    oldBox.deleteFromDisk();

    await super.renameWalletFiles(newWalletName);
  }

  @action
  @override
  Future<void> rescan({
    required int height,
    int? chainTip,
    ScanData? scanData,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    _syncTimer?.cancel();
    int oldHeight = walletInfo.restoreHeight;
    await walletInfo.updateRestoreHeight(height);

    // go through mwebUtxos and clear any that are above the new restore height:
    if (height == 0) {
      await mwebUtxosBox.clear();
      transactionHistory.clear();
    } else {
      for (final utxo in mwebUtxosBox.values) {
        if (utxo.height > height) {
          await mwebUtxosBox.delete(utxo.outputId);
        }
      }
      // TODO: remove transactions that are above the new restore height!
    }

    // reset coin balances and txCount to 0:
    unspentCoins.forEach((coin) {
      if (coin.bitcoinAddressRecord is! BitcoinSilentPaymentAddressRecord)
        coin.bitcoinAddressRecord.balance = 0;
      coin.bitcoinAddressRecord.txCount = 0;
    });

    for (var addressRecord in walletAddresses.allAddresses) {
      addressRecord.balance = 0;
      addressRecord.txCount = 0;
    }

    await startSync();
  }

  @override
  Future<void> init() async {
    await super.init();
    await initMwebUtxosBox();
  }

  Future<void> handleIncoming(MwebUtxo utxo, RpcClient stub) async {
    final status = await stub.status(StatusRequest());
    var date = DateTime.now();
    var confirmations = 0;
    if (utxo.height > 0) {
      date = DateTime.fromMillisecondsSinceEpoch(utxo.blockTime * 1000);
      confirmations = status.blockHeaderHeight - utxo.height + 1;
    }
    var tx = transactionHistory.transactions.values
        .firstWhereOrNull((tx) => tx.outputAddresses?.contains(utxo.outputId) ?? false);

    if (tx == null) {
      tx = ElectrumTransactionInfo(
        WalletType.litecoin,
        id: utxo.outputId,
        height: utxo.height,
        amount: utxo.value.toInt(),
        fee: 0,
        direction: TransactionDirection.incoming,
        isPending: utxo.height == 0,
        date: date,
        confirmations: confirmations,
        inputAddresses: [],
        outputAddresses: [utxo.outputId],
        isReplaced: false,
      );
    }

    // don't update the confirmations if the tx is updated by electrum:
    if (tx.confirmations == 0 || utxo.height != 0) {
      tx.height = utxo.height;
      tx.isPending = utxo.height == 0;
      tx.confirmations = confirmations;
    }

    bool isNew = transactionHistory.transactions[tx.id] == null;

    if (!(tx.outputAddresses?.contains(utxo.address) ?? false)) {
      tx.outputAddresses?.add(utxo.address);
      isNew = true;
    }

    if (isNew) {
      final addressRecord = walletAddresses.allAddresses
          .firstWhereOrNull((addressRecord) => addressRecord.address == utxo.address);
      if (addressRecord == null) {
        print("we don't have this address in the wallet! ${utxo.address}");
        return;
      }

      // if our address isn't in the inputs, update the txCount:
      final inputAddresses = tx.inputAddresses ?? [];
      if (!inputAddresses.contains(utxo.address)) {
        addressRecord.txCount++;
      }

      addressRecord.balance += utxo.value.toInt();
      addressRecord.setAsUsed();
    }

    transactionHistory.addOne(tx);

    if (isNew) {
      // update the unconfirmed balance when a new tx is added:
      // we do this after adding the tx to the history so that sub address balances are updated correctly
      // (since that calculation is based on the tx history)
      await updateBalance();
    }
  }

  Future<void> processMwebUtxos() async {
    if (!mwebEnabled) {
      return;
    }

    int restoreHeight = walletInfo.restoreHeight;
    print("SCANNING FROM HEIGHT: $restoreHeight");
    final req = UtxosRequest(scanSecret: scanSecret, fromHeight: restoreHeight);

    // process new utxos as they come in:
    _utxoStream?.cancel();
    ResponseStream<Utxo>? responseStream = await CwMweb.utxos(req);
    if (responseStream == null) {
      throw Exception("failed to get utxos stream!");
    }
    _utxoStream = responseStream.listen((Utxo sUtxo) async {
      // we're processing utxos, so our balance could still be innacurate:
      // if (syncStatus is! SyncronizingSyncStatus && syncStatus is! SyncingSyncStatus) {
      //   syncStatus = SyncronizingSyncStatus();
      // }

      final utxo = MwebUtxo(
        address: sUtxo.address,
        blockTime: sUtxo.blockTime,
        height: sUtxo.height,
        outputId: sUtxo.outputId,
        value: sUtxo.value.toInt(),
      );

      // if (mwebUtxosBox.containsKey(utxo.outputId)) {
      //   // we've already stored this utxo, skip it:
      //   return;
      // }

      await updateUnspent();
      await updateBalance();

      final mwebAddrs = (walletAddresses as LitecoinWalletAddresses).mwebAddrs;

      // don't process utxos with addresses that are not in the mwebAddrs list:
      if (utxo.address.isNotEmpty && !mwebAddrs.contains(utxo.address)) {
        return;
      }

      await mwebUtxosBox.put(utxo.outputId, utxo);

      await handleIncoming(utxo, _stub);
    });
  }

  Future<void> checkMwebUtxosSpent() async {
    if (!mwebEnabled) {
      return;
    }

    final pendingOutgoingTransactions = transactionHistory.transactions.values
        .where((tx) => tx.direction == TransactionDirection.outgoing && tx.isPending);

    // check if any of the pending outgoing transactions are now confirmed:
    bool updatedAny = false;
    for (final tx in pendingOutgoingTransactions) {
      updatedAny = await checkPendingTransaction(tx) || updatedAny;
    }

    // get output ids of all the mweb utxos that have > 0 height:
    final outputIds =
        mwebUtxosBox.values.where((utxo) => utxo.height > 0).map((utxo) => utxo.outputId).toList();

    final resp = await CwMweb.spent(SpentRequest(outputId: outputIds));
    final spent = resp.outputId;
    if (spent.isEmpty) {
      return;
    }

    final status = await CwMweb.status(StatusRequest());
    final height = await electrumClient.getCurrentBlockChainTip();
    if (height == null || status.blockHeaderHeight != height) return;
    if (status.mwebUtxosHeight != height) return; // we aren't synced

    int amount = 0;
    Set<String> inputAddresses = {};
    var output = convert.AccumulatorSink<Digest>();
    var input = sha256.startChunkedConversion(output);

    for (final outputId in spent) {
      final utxo = mwebUtxosBox.get(outputId);
      await mwebUtxosBox.delete(outputId);
      if (utxo == null) continue;
      final addressRecord = walletAddresses.allAddresses
          .firstWhere((addressRecord) => addressRecord.address == utxo.address);
      if (!inputAddresses.contains(utxo.address)) {
        addressRecord.txCount++;
      }
      addressRecord.balance -= utxo.value.toInt();
      amount += utxo.value.toInt();
      inputAddresses.add(utxo.address);
      input.add(hex.decode(outputId));
    }

    if (inputAddresses.isEmpty) return;
    input.close();
    var digest = output.events.single;
    final tx = ElectrumTransactionInfo(
      WalletType.litecoin,
      id: digest.toString(),
      height: height,
      amount: amount,
      fee: 0,
      direction: TransactionDirection.outgoing,
      isPending: false,
      date: DateTime.fromMillisecondsSinceEpoch(status.blockTime * 1000),
      confirmations: 1,
      inputAddresses: inputAddresses.toList(),
      outputAddresses: [],
      isReplaced: false,
    );

    transactionHistory.addOne(tx);
    await transactionHistory.save();

    if (updatedAny) {
      await updateBalance();
    }
  }

  // checks if a pending transaction is now confirmed, and updates the tx info accordingly:
  Future<bool> checkPendingTransaction(ElectrumTransactionInfo tx) async {
    if (!mwebEnabled) return false;
    if (!tx.isPending) return false;

    final outputId = <String>[], target = <String>{};
    final isHash = RegExp(r'^[a-f0-9]{64}$').hasMatch;
    final spendingOutputIds = tx.inputAddresses?.where(isHash) ?? [];
    final payingToOutputIds = tx.outputAddresses?.where(isHash) ?? [];
    outputId.addAll(spendingOutputIds);
    outputId.addAll(payingToOutputIds);
    target.addAll(spendingOutputIds);

    for (final outputId in payingToOutputIds) {
      final spendingTx = transactionHistory.transactions.values
          .firstWhereOrNull((tx) => tx.inputAddresses?.contains(outputId) ?? false);
      if (spendingTx != null && !spendingTx.isPending) {
        target.add(outputId);
      }
    }

    if (outputId.isEmpty) {
      return false;
    }

    final resp = await CwMweb.spent(SpentRequest(outputId: outputId));
    if (!setEquals(resp.outputId.toSet(), target)) {
      return false;
    }

    final status = await CwMweb.status(StatusRequest());
    tx.height = status.mwebUtxosHeight;
    tx.confirmations = 1;
    tx.isPending = false;
    await transactionHistory.save();
    return true;
  }

  Future<void> updateUnspent() async {
    await checkMwebUtxosSpent();
    await updateAllUnspents();
  }

  @override
  @action
  Future<void> updateAllUnspents() async {
    // get ltc unspents:
    await super.updateAllUnspents();

    if (!mwebEnabled) {
      return;
    }
    await getStub();

    // add the mweb unspents to the list:
    List<BitcoinUnspent> mwebUnspentCoins = [];
    // update mweb unspents:
    final mwebAddrs = (walletAddresses as LitecoinWalletAddresses).mwebAddrs;
    mwebUtxosBox.keys.forEach((dynamic oId) {
      final String outputId = oId as String;
      final utxo = mwebUtxosBox.get(outputId);
      if (utxo == null) {
        return;
      }
      if (utxo.address.isEmpty) {
        // not sure if a bug or a special case but we definitely ignore these
        return;
      }
      final addressRecord = walletAddresses.allAddresses
          .firstWhereOrNull((addressRecord) => addressRecord.address == utxo.address);

      if (addressRecord == null) {
        print("utxo contains an address that is not in the wallet: ${utxo.address}");
        return;
      }
      final unspent = BitcoinUnspent(
        addressRecord,
        outputId,
        utxo.value.toInt(),
        mwebAddrs.indexOf(utxo.address),
      );
      if (unspent.vout == 0) {
        unspent.isChange = true;
      }
      mwebUnspentCoins.add(unspent);
    });
    unspentCoins.addAll(mwebUnspentCoins);
  }

  @override
  Future<ElectrumBalance> fetchBalances() async {
    final balance = await super.fetchBalances();
    if (!mwebEnabled) {
      return balance;
    }
    await getStub();

    int confirmed = balance.confirmed;
    int unconfirmed = balance.unconfirmed;
    int confirmedMweb = 0;
    int unconfirmedMweb = 0;
    try {
      mwebUtxosBox.values.forEach((utxo) {
        if (utxo.height > 0) {
          confirmedMweb += utxo.value.toInt();
        } else {
          unconfirmedMweb += utxo.value.toInt();
        }
      });
      if (unconfirmedMweb > 0) {
        unconfirmedMweb = -1 * (confirmedMweb - unconfirmedMweb);
      }
    } catch (_) {}

    // update unspent balances:
    await updateUnspent();

    for (var addressRecord in walletAddresses.allAddresses) {
      addressRecord.balance = 0;
      addressRecord.txCount = 0;
    }

    unspentCoins.forEach((coin) {
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
        super.addCoinInfo(coin);
      }
    });

    // update the txCount for each address using the tx history, since we can't rely on mwebd
    // to have an accurate count, we should just keep it in sync with what we know from the tx history:
    for (final tx in transactionHistory.transactions.values) {
      // if (tx.isPending) continue;
      if (tx.inputAddresses == null || tx.outputAddresses == null) {
        continue;
      }
      final txAddresses = tx.inputAddresses! + tx.outputAddresses!;
      for (final address in txAddresses) {
        final addressRecord = walletAddresses.allAddresses
            .firstWhereOrNull((addressRecord) => addressRecord.address == address);
        if (addressRecord == null) {
          continue;
        }
        addressRecord.txCount++;
      }
    }

    return ElectrumBalance(
      confirmed: confirmed,
      unconfirmed: unconfirmed,
      frozen: balance.frozen,
      secondConfirmed: confirmedMweb,
      secondUnconfirmed: unconfirmedMweb,
    );
  }

  @override
  int feeRate(TransactionPriority priority) {
    if (priority is LitecoinTransactionPriority) {
      switch (priority) {
        case LitecoinTransactionPriority.slow:
          return 1;
        case LitecoinTransactionPriority.medium:
          return 2;
        case LitecoinTransactionPriority.fast:
          return 3;
      }
    }

    return 0;
  }

  @override
  Future<int> calcFee({
    required List<UtxoWithAddress> utxos,
    required List<BitcoinBaseOutput> outputs,
    required BasedUtxoNetwork network,
    String? memo,
    required int feeRate,
    List<ECPrivateInfo>? inputPrivKeyInfos,
    List<Outpoint>? vinOutpoints,
  }) async {
    final spendsMweb = utxos.any((utxo) => utxo.utxo.scriptType == SegwitAddresType.mweb);
    final paysToMweb = outputs
        .any((output) => output.toOutput.scriptPubKey.getAddressType() == SegwitAddresType.mweb);
    if (!spendsMweb && !paysToMweb) {
      return await super.calcFee(
        utxos: utxos,
        outputs: outputs,
        network: network,
        memo: memo,
        feeRate: feeRate,
        inputPrivKeyInfos: inputPrivKeyInfos,
        vinOutpoints: vinOutpoints,
      );
    }

    if (!mwebEnabled) {
      throw Exception("MWEB is not enabled! can't calculate fee without starting the mweb server!");
    }

    if (outputs.length == 1 && outputs[0].toOutput.amount == BigInt.zero) {
      outputs = [
        BitcoinScriptOutput(
            script: outputs[0].toOutput.scriptPubKey, value: utxos.sumOfUtxosValue())
      ];
    }
    // https://github.com/ltcmweb/mwebd?tab=readme-ov-file#fee-estimation
    final preOutputSum =
        outputs.fold<BigInt>(BigInt.zero, (acc, output) => acc + output.toOutput.amount);
    final fee = utxos.sumOfUtxosValue() - preOutputSum;
    final txb =
        BitcoinTransactionBuilder(utxos: utxos, outputs: outputs, fee: fee, network: network);
    final resp = await CwMweb.create(CreateRequest(
        rawTx: txb.buildTransaction((a, b, c, d) => '').toBytes(),
        scanSecret: scanSecret,
        spendSecret: spendSecret,
        feeRatePerKb: Int64(feeRate * 1000),
        dryRun: true));
    final tx = BtcTransaction.fromRaw(hex.encode(resp.rawTx));
    final posUtxos = utxos
        .where((utxo) => tx.inputs
            .any((input) => input.txId == utxo.utxo.txHash && input.txIndex == utxo.utxo.vout))
        .toList();
    final posOutputSum = tx.outputs.fold<int>(0, (acc, output) => acc + output.amount.toInt());
    final mwebInputSum = utxos.sumOfUtxosValue() - posUtxos.sumOfUtxosValue();
    final expectedPegin = max(0, (preOutputSum - mwebInputSum).toInt());
    var feeIncrease = posOutputSum - expectedPegin;
    if (expectedPegin > 0 && fee == BigInt.zero) {
      feeIncrease += await super.calcFee(
              utxos: posUtxos,
              outputs: tx.outputs
                  .map((output) =>
                      BitcoinScriptOutput(script: output.scriptPubKey, value: output.amount))
                  .toList(),
              network: network,
              memo: memo,
              feeRate: feeRate) +
          feeRate * 41;
    }
    return fee.toInt() + feeIncrease;
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      var tx = await super.createTransaction(credentials) as PendingBitcoinTransaction;
      tx.isMweb = mwebEnabled;

      if (!mwebEnabled) {
        return tx;
      }
      await waitForMwebAddresses();
      await getStub();

      final resp = await CwMweb.create(CreateRequest(
        rawTx: hex.decode(tx.hex),
        scanSecret: scanSecret,
        spendSecret: spendSecret,
        feeRatePerKb: Int64.parseInt(tx.feeRate) * 1000,
      ));
      final tx2 = BtcTransaction.fromRaw(hex.encode(resp.rawTx));

      // check if any of the inputs of this transaction are hog-ex:
      tx2.inputs.forEach((txInput) {
        bool isHogEx = true;

        final utxo = unspentCoins
            .firstWhere((utxo) => utxo.hash == txInput.txId && utxo.vout == txInput.txIndex);

        // TODO: detect actual hog-ex inputs

        if (!isHogEx) {
          return;
        }

        int confirmations = utxo.confirmations ?? 0;
        if (confirmations < 6) {
          throw Exception(
              "A transaction input has less than 6 confirmations, please try again later.");
        }
      });

      tx.hexOverride = tx2
          .copyWith(
              witnesses: tx2.inputs.asMap().entries.map((e) {
            final utxo = unspentCoins
                .firstWhere((utxo) => utxo.hash == e.value.txId && utxo.vout == e.value.txIndex);
            final key = generateECPrivate(
                hd: utxo.bitcoinAddressRecord.isHidden
                    ? walletAddresses.sideHd
                    : walletAddresses.mainHd,
                index: utxo.bitcoinAddressRecord.index,
                network: network);
            final digest = tx2.getTransactionSegwitDigit(
              txInIndex: e.key,
              script: key.getPublic().toP2pkhAddress().toScriptPubKey(),
              amount: BigInt.from(utxo.value),
            );
            return TxWitnessInput(stack: [key.signInput(digest), key.getPublic().toHex()]);
          }).toList())
          .toHex();
      tx.outputAddresses = resp.outputId;

      return tx
        ..addListener((transaction) async {
          final addresses = <String>{};
          transaction.inputAddresses?.forEach((id) async {
            final utxo = mwebUtxosBox.get(id);
            // await mwebUtxosBox.delete(id);// gets deleted in checkMwebUtxosSpent
            if (utxo == null) return;
            final addressRecord = walletAddresses.allAddresses
                .firstWhere((addressRecord) => addressRecord.address == utxo.address);
            if (!addresses.contains(utxo.address)) {
              addresses.add(utxo.address);
            }
            addressRecord.balance -= utxo.value.toInt();
          });
          transaction.inputAddresses?.addAll(addresses);

          transactionHistory.addOne(transaction);
          await updateUnspent();
          await updateBalance();
        });
    } catch (e, s) {
      print(e);
      print(s);
      if (e.toString().contains("commit failed")) {
        throw Exception("Transaction commit failed (no peers responded), please try again.");
      }
      rethrow;
    }
  }

  @override
  Future<void> save() async {
    await super.save();
  }

  @override
  Future<void> close() async {
    _utxoStream?.cancel();
    _feeRatesTimer?.cancel();
    _syncTimer?.cancel();
    await stopSync();
    await super.close();
  }

  Future<void> setMwebEnabled(bool enabled) async {
    if (mwebEnabled == enabled) {
      return;
    }

    mwebEnabled = enabled;
    (walletAddresses as LitecoinWalletAddresses).mwebEnabled = enabled;
    await stopSync();
    await startSync();
  }

  Future<RpcClient> getStub() async {
    _stub = await CwMweb.stub();
    return _stub;
  }

  Future<StatusResponse> getStatusRequest() async {
    final resp = await CwMweb.status(StatusRequest());
    return resp;
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    final index = address != null
        ? walletAddresses.allAddresses.firstWhere((element) => element.address == address).index
        : null;
    final HD = index == null ? hd : hd.childKey(Bip32KeyIndex(index));
    final priv = ECPrivate.fromHex(HD.privateKey.privKey.toHex());

    final privateKey = ECDSAPrivateKey.fromBytes(
      priv.toBytes(),
      Curves.generatorSecp256k1,
    );

    final signature =
        signLitecoinMessage(utf8.encode(message), privateKey: privateKey, bipPrive: priv.prive);

    return base64Encode(signature);
  }

  List<int> _magicPrefix(List<int> message, List<int> messagePrefix) {
    final encodeLength = IntUtils.encodeVarint(message.length);

    return [...messagePrefix, ...encodeLength, ...message];
  }

  List<int> signLitecoinMessage(List<int> message,
      {required ECDSAPrivateKey privateKey, required Bip32PrivateKey bipPrive}) {
    String messagePrefix = '\x19Litecoin Signed Message:\n';
    final messageHash = QuickCrypto.sha256Hash(magicMessage(message, messagePrefix));
    final signingKey = EcdsaSigningKey(privateKey);
    ECDSASignature ecdsaSign =
        signingKey.signDigestDeterminstic(digest: messageHash, hashFunc: () => SHA256());
    final n = Curves.generatorSecp256k1.order! >> 1;
    BigInt newS;
    if (ecdsaSign.s.compareTo(n) > 0) {
      newS = Curves.generatorSecp256k1.order! - ecdsaSign.s;
    } else {
      newS = ecdsaSign.s;
    }
    final rawSig = ECDSASignature(ecdsaSign.r, newS);
    final rawSigBytes = rawSig.toBytes(BitcoinSignerUtils.baselen);

    final pub = bipPrive.publicKey;
    final ECDomainParameters curve = ECCurve_secp256k1();
    final point = curve.curve.decodePoint(pub.point.toBytes());

    final rawSigEc = ECSignature(rawSig.r, rawSig.s);

    final recId = SignUtils.findRecoveryId(
      SignUtils.getHexString(messageHash, offset: 0, length: messageHash.length),
      rawSigEc,
      Uint8List.fromList(pub.uncompressed),
    );

    final v = recId + 27 + (point!.isCompressed ? 4 : 0);

    final combined = Uint8List.fromList([v, ...rawSigBytes]);

    return combined;
  }

  List<int> magicMessage(List<int> message, String messagePrefix) {
    final prefixBytes = StringUtils.encode(messagePrefix);
    final magic = _magicPrefix(message, prefixBytes);
    return QuickCrypto.sha256Hash(magic);
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address = null}) async {
    if (address == null) {
      return false;
    }

    List<int> sigDecodedBytes = [];

    if (signature.endsWith('=')) {
      sigDecodedBytes = base64.decode(signature);
    } else {
      sigDecodedBytes = hex.decode(signature);
    }

    if (sigDecodedBytes.length != 64 && sigDecodedBytes.length != 65) {
      throw ArgumentException(
          "litecoin signature must be 64 bytes without recover-id or 65 bytes with recover-id");
    }

    String messagePrefix = '\x19Litecoin Signed Message:\n';
    final messageHash = QuickCrypto.sha256Hash(magicMessage(utf8.encode(message), messagePrefix));

    List<int> correctSignature =
        sigDecodedBytes.length == 65 ? sigDecodedBytes.sublist(1) : List.from(sigDecodedBytes);
    List<int> rBytes = correctSignature.sublist(0, 32);
    List<int> sBytes = correctSignature.sublist(32);
    final sig = ECDSASignature(BigintUtils.fromBytes(rBytes), BigintUtils.fromBytes(sBytes));

    List<int> possibleRecoverIds = [0, 1];

    final baseAddress = RegexUtils.addressTypeFromStr(address, network);

    for (int recoveryId in possibleRecoverIds) {
      final pubKey = sig.recoverPublicKey(messageHash, Curves.generatorSecp256k1, recoveryId);
      final recoveredPub = ECPublic.fromBytes(pubKey!.toBytes());

      String? recoveredAddress;

      if (baseAddress is P2pkAddress) {
        recoveredAddress = recoveredPub.toP2pkAddress().toAddress(network);
      } else if (baseAddress is P2pkhAddress) {
        recoveredAddress = recoveredPub.toP2pkhAddress().toAddress(network);
      } else if (baseAddress is P2wshAddress) {
        recoveredAddress = recoveredPub.toP2wshAddress().toAddress(network);
      } else if (baseAddress is P2wpkhAddress) {
        recoveredAddress = recoveredPub.toP2wpkhAddress().toAddress(network);
      }

      if (recoveredAddress == address) {
        return true;
      }
    }

    return false;
  }
}
