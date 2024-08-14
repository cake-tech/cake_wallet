import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart';
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/mweb_utxo.dart';
import 'package:cw_mweb/mwebd.pbgrpc.dart';
import 'package:fixnum/fixnum.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/litecoin_wallet_addresses.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_mweb/cw_mweb.dart';

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
    String? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
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
      mainHd: hd,
      sideHd: accountHD.childKey(Bip32KeyIndex(1)),
      network: network,
      mwebHd: mwebHd,
    );
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
    CwMweb.stub().then((value) {
      _stub = value;
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
        seedBytes = await mnemonicToSeedBytes(mnemonic);
        break;
    }
    return LitecoinWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      encryptionFileUtils: encryptionFileUtils,
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

    return LitecoinWallet(
      mnemonic: keysData.mnemonic!,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp?.addresses,
      initialBalance: snp?.balance,
      seedBytes: await mnemonicToSeedBytes(keysData.mnemonic!),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      addressPageType: snp?.addressPageType,
      alwaysScan: alwaysScan,
    );
  }

  @action
  @override
  Future<void> startSync() async {
    print("STARTING SYNC");
    if (!mwebEnabled) {
      syncStatus = SyncronizingSyncStatus();
      await subscribeForUpdates();
      await updateTransactions();
      syncStatus = SyncedSyncStatus();
      return;
    }

    await subscribeForUpdates();
    await updateTransactions();
    await updateFeeRates();

    _feeRatesTimer?.cancel();
    _feeRatesTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async => await updateFeeRates());

    _stub = await CwMweb.stub();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (syncStatus is FailedSyncStatus) return;
      final nodeHeight = await electrumClient.getCurrentBlockChainTip() ?? 0;
      final resp = await _stub.status(StatusRequest());

      if (resp.blockHeaderHeight < nodeHeight) {
        int h = resp.blockHeaderHeight;
        syncStatus = SyncingSyncStatus(height - h, h / height);
      } else if (resp.mwebHeaderHeight < nodeHeight) {
        int h = resp.mwebHeaderHeight;
        syncStatus = SyncingSyncStatus(height - h, h / height);
      } else if (resp.mwebUtxosHeight < nodeHeight) {
        syncStatus = SyncingSyncStatus(1, 0.999);
      } else {
        // prevent unnecessary reaction triggers:
        if (syncStatus is! SyncedSyncStatus) {
          syncStatus = SyncedSyncStatus();
        }

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
      }
    });
    updateUnspent();
    fetchBalances();
    // this runs in the background and processes new utxos as they come in:
    processMwebUtxos();
  }

  @action
  @override
  Future<void> stopSync() async {
    _syncTimer?.cancel();
    _utxoStream?.cancel();
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

    final oldBox = await Hive.openBox<MwebUtxo>(oldBoxName);
    mwebUtxosBox = await CakeHive.openBox<MwebUtxo>(newBoxName);
    for (final key in oldBox.keys) {
      await mwebUtxosBox.put(key, oldBox.get(key)!);
    }

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
    await mwebUtxosBox.clear();
    transactionHistory.clear();
    await walletInfo.updateRestoreHeight(height);

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
      );
    }

    bool isNew = transactionHistory.transactions[tx.id] == null;

    // don't update the confirmations if the tx is updated by electrum:
    if (tx.confirmations == 0 || utxo.height != 0) {
      tx.height = utxo.height;
      tx.isPending = utxo.height == 0;
      tx.confirmations = confirmations;
    }

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
    int restoreHeight = walletInfo.restoreHeight;
    print("SCANNING FROM HEIGHT: $restoreHeight");
    final req = UtxosRequest(scanSecret: scanSecret, fromHeight: restoreHeight);

    // process old utxos:
    // for (final utxo in mwebUtxosBox.values) {
    //   if (utxo.address.isEmpty) {
    //     continue;
    //   }

    //   // if (walletInfo.restoreHeight > utxo.height) {
    //   //   continue;
    //   // }
    //   // await handleIncoming(utxo, _stub);

    //   if (utxo.height > walletInfo.restoreHeight) {
    //     await walletInfo.updateRestoreHeight(utxo.height);
    //   }
    // }

    // process new utxos as they come in:
    _utxoStream?.cancel();
    _utxoStream = _stub.utxos(req).listen((Utxo sUtxo) async {
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

      // if (utxo.address.isEmpty) {
      //   await updateUnspent();
      //   await updateBalance();
      //   initDone = true;
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
    while ((await Future.wait(transactionHistory.transactions.values
            .where((tx) => tx.direction == TransactionDirection.outgoing && tx.isPending)
            .map(checkPendingTransaction)))
        .any((x) => x));
    final outputIds =
        mwebUtxosBox.values.where((utxo) => utxo.height > 0).map((utxo) => utxo.outputId).toList();

    final resp = await _stub.spent(SpentRequest(outputId: outputIds));
    final spent = resp.outputId;
    if (spent.isEmpty) return;
    final status = await _stub.status(StatusRequest());
    final height = await electrumClient.getCurrentBlockChainTip();
    if (height == null || status.blockHeaderHeight != height) return;
    if (status.mwebUtxosHeight != height) return;
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
        // print("COUNT UPDATED HERE 3!!!!! ${addressRecord.address} ${addressRecord.txCount} !!!!!!");
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
    );
    print("BEING ADDED HERE@@@@@@@@@@@@@@@@@@@@@@@2");

    transactionHistory.addOne(tx);
    await transactionHistory.save();
  }

  Future<bool> checkPendingTransaction(ElectrumTransactionInfo tx) async {
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
    final resp = await _stub.spent(SpentRequest(outputId: outputId));
    if (!setEquals(resp.outputId.toSet(), target)) return false;
    final status = await _stub.status(StatusRequest());
    if (!tx.isPending) return false;
    tx.height = status.mwebUtxosHeight;
    tx.confirmations = 1;
    tx.isPending = false;
    await transactionHistory.save();
    return true;
  }

  @override
  Future<void> updateUnspent() async {
    await super.updateUnspent();
    await checkMwebUtxosSpent();
  }

  @override
  @action
  Future<void> updateAllUnspents() async {
    List<BitcoinUnspent> updatedUnspentCoins = [];

    await Future.wait(walletAddresses.allAddresses.map((address) async {
      updatedUnspentCoins.addAll(await fetchUnspent(address));
    }));

    if (mwebEnabled) {
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
        updatedUnspentCoins.add(unspent);
      });
    }

    unspentCoins = updatedUnspentCoins;
  }

  @override
  Future<ElectrumBalance> fetchBalances() async {
    final balance = await super.fetchBalances();
    var confirmed = balance.confirmed;
    var unconfirmed = balance.unconfirmed;
    mwebUtxosBox.values.forEach((utxo) {
      if (utxo.height > 0) {
        confirmed += utxo.value.toInt();
      } else {
        unconfirmed += utxo.value.toInt();
      }
    });

    // update unspent balances:

    // reset coin balances and txCount to 0:
    // unspentCoins.forEach((coin) {
    //   if (coin.bitcoinAddressRecord is! BitcoinSilentPaymentAddressRecord)
    //     coin.bitcoinAddressRecord.balance = 0;
    //   coin.bitcoinAddressRecord.txCount = 0;
    // });
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

    await updateUnspent();

    return ElectrumBalance(confirmed: confirmed, unconfirmed: unconfirmed, frozen: balance.frozen);
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
    if (outputs.length == 1 && outputs[0].toOutput.amount == BigInt.zero) {
      outputs = [
        BitcoinScriptOutput(
            script: outputs[0].toOutput.scriptPubKey, value: utxos.sumOfUtxosValue())
      ];
    }
    final preOutputSum =
        outputs.fold<BigInt>(BigInt.zero, (acc, output) => acc + output.toOutput.amount);
    final fee = utxos.sumOfUtxosValue() - preOutputSum;
    final txb =
        BitcoinTransactionBuilder(utxos: utxos, outputs: outputs, fee: fee, network: network);
    final resp = await _stub.create(CreateRequest(
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

      final resp = await _stub.create(CreateRequest(
        rawTx: hex.decode(tx.hex),
        scanSecret: scanSecret,
        spendSecret: spendSecret,
        feeRatePerKb: Int64.parseInt(tx.feeRate) * 1000,
      ));
      final tx2 = BtcTransaction.fromRaw(hex.encode(resp.rawTx));
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
      tx.outputs = resp.outputId;
      return tx
        ..addListener((transaction) async {
          final addresses = <String>{};
          transaction.inputAddresses?.forEach((id) async {
            final utxo = mwebUtxosBox.get(id);
            await mwebUtxosBox.delete(id);
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
    await super.close();
    await mwebUtxosBox.close();
    _syncTimer?.cancel();
    _utxoStream?.cancel();
  }

  void setMwebEnabled(bool enabled) {
    if (mwebEnabled == enabled) {
      return;
    }

    mwebEnabled = enabled;
    stopSync();
    startSync();
  }

  Future<RpcClient> getStub() async {
    _stub = await CwMweb.stub();
    return _stub;
  }

  Future<StatusResponse> getStatusRequest() async {
    await getStub();
    final resp = await _stub.status(StatusRequest());
    return resp;
  }
}
