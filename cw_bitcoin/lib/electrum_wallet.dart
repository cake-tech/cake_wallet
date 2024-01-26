import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin_base;
import 'package:collection/collection.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_no_inputs_exception.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_transaction_wrong_balance_exception.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_transaction_history.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/litecoin_network.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/script_hash.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:rxdart/subjects.dart';
import 'package:http/http.dart' as http;

part 'electrum_wallet.g.dart';

class ElectrumWallet = ElectrumWalletBase with _$ElectrumWallet;

abstract class ElectrumWalletBase
    extends WalletBase<ElectrumBalance, ElectrumTransactionHistory, ElectrumTransactionInfo>
    with Store {
  ElectrumWalletBase(
      {required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required this.networkType,
      required this.mnemonic,
      required Uint8List seedBytes,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumClient? electrumClient,
      ElectrumBalance? initialBalance,
      CryptoCurrency? currency})
      : hd = currency == CryptoCurrency.bch
            ? bitcoinCashHDWallet(seedBytes)
            : bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/0"),
        syncStatus = NotConnectedSyncStatus(),
        _password = password,
        _feeRates = <int>[],
        _isTransactionUpdating = false,
        isEnabledAutoGenerateSubaddress = true,
        unspentCoins = [],
        _scripthashesUpdateSubject = {},
        balance = ObservableMap<CryptoCurrency, ElectrumBalance>.of(currency != null
            ? {
                currency:
                    initialBalance ?? const ElectrumBalance(confirmed: 0, unconfirmed: 0, frozen: 0)
              }
            : {}),
        this.unspentCoinsInfo = unspentCoinsInfo,
        this.network = networkType == bitcoin.bitcoin
            ? BitcoinNetwork.mainnet
            : networkType == litecoinNetwork
                ? LitecoinNetwork.mainnet
                : BitcoinNetwork.testnet,
        this.isTestnet = networkType == bitcoin.testnet,
        super(walletInfo) {
    this.electrumClient = electrumClient ?? ElectrumClient();
    this.walletInfo = walletInfo;
    transactionHistory = ElectrumTransactionHistory(walletInfo: walletInfo, password: password);
  }

  static bitcoin.HDWallet bitcoinCashHDWallet(Uint8List seedBytes) =>
      bitcoin.HDWallet.fromSeed(seedBytes).derivePath("m/44'/145'/0'/0");

  static int estimatedTransactionSize(int inputsCount, int outputsCounts) =>
      inputsCount * 68 + outputsCounts * 34 + 10;

  final bitcoin.HDWallet hd;
  final String mnemonic;

  @override
  @observable
  bool isEnabledAutoGenerateSubaddress;

  late ElectrumClient electrumClient;
  Box<UnspentCoinsInfo> unspentCoinsInfo;

  @override
  late ElectrumWalletAddresses walletAddresses;

  @override
  @observable
  late ObservableMap<CryptoCurrency, ElectrumBalance> balance;

  @override
  @observable
  SyncStatus syncStatus;

  List<String> get scriptHashes =>
      walletAddresses.addresses.map((addr) => scriptHash(addr.address, network: network)).toList();

  List<String> get publicScriptHashes => walletAddresses.allAddresses
      .where((addr) => !addr.isHidden)
      .map((addr) => scriptHash(addr.address, network: network))
      .toList();

  String get xpub => hd.base58!;

  @override
  String get seed => mnemonic;

  bitcoin.NetworkType networkType;
  BasedUtxoNetwork network;

  @override
  bool? isTestnet;

  @override
  BitcoinWalletKeys get keys =>
      BitcoinWalletKeys(wif: hd.wif!, privateKey: hd.privKey!, publicKey: hd.pubKey!);

  String _password;
  List<BitcoinUnspent> unspentCoins;
  List<int> _feeRates;
  Map<String, BehaviorSubject<Object>?> _scripthashesUpdateSubject;
  bool _isTransactionUpdating;

  void Function(FlutterErrorDetails)? _onError;

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();
    await save();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await walletAddresses.discoverAddresses();
      await updateTransactions();
      _subscribeForUpdates();
      await updateUnspent();
      await updateBalance();
      _feeRates = await electrumClient.feeRates();

      Timer.periodic(
          const Duration(minutes: 1), (timer) async => _feeRates = await electrumClient.feeRates());

      syncStatus = SyncedSyncStatus();
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await electrumClient.connectToUri(node.uri);
      electrumClient.onConnectionStatusChange = (bool isConnected) {
        if (!isConnected) {
          syncStatus = LostConnectionSyncStatus();
        }
      };
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      print(e.toString());
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    try {
      final outputs = <BitcoinOutput>[];
      final outputAddresses = <BitcoinAddress>[];
      final transactionCredentials = credentials as BitcoinTransactionCredentials;
      final hasMultiDestination = transactionCredentials.outputs.length > 1;
      final sendAll = !hasMultiDestination && transactionCredentials.outputs.first.sendAll;

      var credentialsAmount = 0;
      var minAmount = 0.0;

      for (final out in transactionCredentials.outputs) {
        final outputAddress = out.isParsedAddress ? out.extractedAddress! : out.address;
        BitcoinAddress address;

        if (P2pkhAddress.REGEX.hasMatch(outputAddress)) {
          address = P2pkhAddress.fromAddress(address: outputAddress, network: network);
          minAmount += P2pkhAddress.outputSizeVB;
        } else if (P2shAddress.REGEX.hasMatch(outputAddress)) {
          address = P2shAddress.fromAddress(address: outputAddress, network: network);
          minAmount += P2shAddress.outputSizeVB;
        } else if (P2wshAddress.REGEX.hasMatch(outputAddress)) {
          address = P2wshAddress.fromAddress(address: outputAddress, network: network);
          minAmount += P2wshAddress.outputSizeVB;
        } else if (P2trAddress.REGEX.hasMatch(outputAddress)) {
          address = P2trAddress.fromAddress(address: outputAddress, network: network);
          minAmount += P2trAddress.outputSizeVB;
        } else if (P2wpkhAddress.REGEX.hasMatch(outputAddress)) {
          address = P2wpkhAddress.fromAddress(address: outputAddress, network: network);
          minAmount += P2wpkhAddress.outputSizeVB;
        } else {
          // TODO: proper error here for output address not found
          throw BitcoinTransactionWrongBalanceException(currency);
        }

        outputAddresses.add(address);

        if (hasMultiDestination) {
          if (out.sendAll || out.formattedCryptoAmount! <= 0) {
            throw BitcoinTransactionWrongBalanceException(currency);
          }

          final outputAmount = out.formattedCryptoAmount!;
          credentialsAmount += outputAmount;

          outputs.add(BitcoinOutput(address: address, value: BigInt.from(outputAmount)));
        } else {
          if (!sendAll) {
            final outputAmount = out.formattedCryptoAmount!;
            credentialsAmount += outputAmount;
            outputs.add(BitcoinOutput(address: address, value: BigInt.from(outputAmount)));
          } else {
            // The value will be changed after estimating the Tx size and deducting the fee from the total
            outputs.add(BitcoinOutput(address: address, value: BigInt.from(0)));
          }
        }
      }

      final utxos = <UtxoWithAddress>[];
      final List<ECPrivate> privateKeys = [];

      var leftAmount = credentialsAmount;
      var overheadSizeVB = 0.0;
      var allInputsAmount = 0;

      for (final utx in unspentCoins) {
        if (utx.isSending) {
          allInputsAmount += utx.value;
          leftAmount = leftAmount - utx.value;

          BitcoinAddress address;
          BitcoinAddressType scriptType;

          ECPrivate privkey;
          ECPrivate mainPrivkey = generateECPrivate(
              hd: walletAddresses.mainHd, index: utx.bitcoinAddressRecord.index, network: network);
          ECPrivate sidePrivkey = generateECPrivate(
              hd: walletAddresses.sideHd, index: utx.bitcoinAddressRecord.index, network: network);

          if (P2pkhAddress.REGEX.hasMatch(utx.address)) {
            address = P2pkhAddress.fromAddress(address: utx.address, network: network);
            minAmount += P2pkhAddress.inputSizeVB;
            scriptType = BitcoinAddressType.p2pkh;
            if (P2pkhAddress.fromPubkey(pubkey: mainPrivkey.getPublic().toHex())
                    .toAddress(network) ==
                utx.address) {
              privkey = mainPrivkey;
            } else {
              privkey = sidePrivkey;
            }
          } else if (P2wshAddress.REGEX.hasMatch(utx.address)) {
            address = P2wshAddress.fromAddress(address: utx.address, network: network);
            minAmount += P2wshAddress.inputSizeVB;
            scriptType = BitcoinAddressType.p2wsh;
            if (P2wshAddress.fromPubkey(pubkey: mainPrivkey.getPublic().toHex())
                    .toAddress(network) ==
                utx.address) {
              privkey = mainPrivkey;
            } else {
              privkey = sidePrivkey;
            }
          } else if (P2trAddress.REGEX.hasMatch(utx.address)) {
            address = P2trAddress.fromAddress(address: utx.address, network: network);
            minAmount += P2trAddress.inputSizeVB;
            scriptType = BitcoinAddressType.p2tr;
            if (P2trAddress.fromPubkey(pubkey: mainPrivkey.getPublic().toHex())
                    .toAddress(network) ==
                utx.address) {
              privkey = mainPrivkey;
            } else {
              privkey = sidePrivkey;
            }
          } else {
            address = P2wpkhAddress.fromAddress(address: utx.address, network: network);
            minAmount += P2wpkhAddress.inputSizeVB;
            scriptType = BitcoinAddressType.p2wpkh;
            if (P2wpkhAddress.fromPubkey(pubkey: mainPrivkey.getPublic().toHex())
                    .toAddress(network) ==
                utx.address) {
              privkey = mainPrivkey;
            } else {
              privkey = sidePrivkey;
            }
          }

          privateKeys.add(privkey);

          if (utx.bitcoinAddressRecord.type == BitcoinAddressType.p2pkh) {
            overheadSizeVB = P2pkhAddress.overheadSizeVB;
          } else {
            overheadSizeVB = P2wpkhAddress.overheadSizeVB;
          }

          utxos.add(
            UtxoWithAddress(
              utxo: BitcoinUtxo(
                txHash: utx.hash,
                value: BigInt.from(utx.value),
                vout: utx.vout,
                scriptType: scriptType,
              ),
              ownerDetails:
                  UtxoAddressDetails(publicKey: privkey.getPublic().toHex(), address: address),
            ),
          );

          if (!sendAll && leftAmount <= 0) {
            break;
          }
        }
      }

      if (utxos.isEmpty) {
        throw BitcoinTransactionNoInputsException();
      }

      minAmount += overheadSizeVB;

      if (!sendAll) {
        final changeValue = allInputsAmount - credentialsAmount;

        if (changeValue > 0) {
          final changeAddress = await walletAddresses.getChangeAddress();
          BitcoinAddress address;
          if (P2pkhAddress.REGEX.hasMatch(changeAddress)) {
            address = P2pkhAddress.fromAddress(address: changeAddress, network: network);
          } else if (P2wshAddress.REGEX.hasMatch(changeAddress)) {
            address = P2wshAddress.fromAddress(address: changeAddress, network: network);
          } else if (P2trAddress.REGEX.hasMatch(changeAddress)) {
            address = P2trAddress.fromAddress(address: changeAddress, network: network);
          } else {
            address = P2wpkhAddress.fromAddress(address: changeAddress, network: network);
          }

          outputAddresses.add(address);
          outputs.add(BitcoinOutput(address: address, value: BigInt.from(changeValue)));
        }
      }

      final estimatedSize = BitcoinTransactionBuilder.estimateTransactionSize(
          utxos: utxos, outputs: outputAddresses, network: network);

      final fee = transactionCredentials.feeRate != null
          ? feeAmountWithFeeRate(transactionCredentials.feeRate!, 0, 0, size: estimatedSize)
          : feeAmountForPriority(transactionCredentials.priority!, 0, 0, size: estimatedSize);

      if (fee == 0) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      var amount = credentialsAmount;

      final lastOutput = outputs.last;
      if (!sendAll) {
        // Here, lastOutput is change, deduct the fee from it
        outputs[outputs.length - 1] =
            BitcoinOutput(address: lastOutput.address, value: lastOutput.value - BigInt.from(fee));
      } else {
        // Here, if sendAll, the output amount equals to the input value - fee to fully spend every input on the transaction and have no amount for change
        amount = allInputsAmount - fee;
        outputs[outputs.length - 1] =
            BitcoinOutput(address: lastOutput.address, value: BigInt.from(amount));
      }

      final totalAmount = amount + fee;

      if (totalAmount > balance[currency]!.confirmed ||
          totalAmount > allInputsAmount ||
          amount < minAmount) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      final txb = BitcoinTransactionBuilder(
          utxos: utxos, outputs: outputs, fee: BigInt.from(fee), network: network);

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        final key =
            privateKeys.firstWhereOrNull((element) => element.getPublic().toHex() == publicKey);

        if (key == null) {
          throw Exception("Cannot find private key");
        }

        if (utxo.utxo.isP2tr()) {
          return key.signTapRoot(txDigest, sighash: sighash);
        } else {
          return key.signInput(txDigest, sigHash: sighash);
        }
      });

      return PendingBitcoinTransaction(transaction, type,
          electrumClient: electrumClient, amount: amount, fee: fee, network: network)
        ..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          await updateBalance();
        });
    } catch (e, s) {
      print(["ERROR", e, s]);
      throw e;
    }
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': walletAddresses.currentReceiveAddressIndexByType,
        'change_address_index': walletAddresses.currentChangeAddressIndexByType,
        'addresses': walletAddresses.allAddresses.map((addr) => addr.toJSON()).toList(),
        'address_page_type': walletInfo.addressPageType.toString(),
        'balance': balance[currency]?.toJSON(),
        'network_type': network == BitcoinNetwork.mainnet ? 'mainnet' : 'testnet',
      });

  int feeRate(TransactionPriority priority) {
    try {
      if (priority is BitcoinTransactionPriority) {
        return _feeRates[priority.raw];
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  int feeAmountForPriority(BitcoinTransactionPriority priority, int inputsCount, int outputsCount,
          {int? size}) =>
      feeRate(priority) * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount, {int? size}) =>
      feeRate * (size ?? estimatedTransactionSize(inputsCount, outputsCount));

  @override
  int calculateEstimatedFee(TransactionPriority? priority, int? amount,
      {int? outputsCount, int? size}) {
    if (priority is BitcoinTransactionPriority) {
      return calculateEstimatedFeeWithFeeRate(feeRate(priority), amount,
          outputsCount: outputsCount, size: size);
    }

    return 0;
  }

  int calculateEstimatedFeeWithFeeRate(int feeRate, int? amount, {int? outputsCount, int? size}) {
    if (size != null) {
      return feeAmountWithFeeRate(feeRate, 0, 0, size: size);
    }

    int inputsCount = 0;

    if (amount != null) {
      int totalValue = 0;

      for (final input in unspentCoins) {
        if (totalValue >= amount) {
          break;
        }

        if (input.isSending) {
          totalValue += input.value;
          inputsCount += 1;
        }
      }

      if (totalValue < amount) return 0;
    } else {
      for (final input in unspentCoins) {
        if (input.isSending) {
          inputsCount += 1;
        }
      }
    }

    // If send all, then we have no change value
    final _outputsCount = outputsCount ?? (amount != null ? 2 : 1);

    return feeAmountWithFeeRate(feeRate, inputsCount, _outputsCount);
  }

  @override
  Future<void> save() async {
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);
    final currentTransactionsFile = File('$currentDirPath/$transactionsHistoryFileName');

    // Copies current wallet files into new wallet name's dir and files
    if (currentWalletFile.existsSync()) {
      final newWalletPath = await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }
    if (currentTransactionsFile.existsSync()) {
      final newDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentTransactionsFile.copy('$newDirPath/$transactionsHistoryFileName');
    }

    // Delete old name's dir and files
    await Directory(currentDirPath).delete(recursive: true);
  }

  @override
  Future<void> changePassword(String password) async {
    _password = password;
    await save();
    await transactionHistory.changePassword(password);
  }

  @override
  Future<void> rescan({required int height}) async => throw UnimplementedError();

  @override
  Future<void> close() async {
    try {
      await electrumClient.close();
    } catch (_) {}
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  Future<void> updateUnspent() async {
    final unspent = await Future.wait(walletAddresses.allAddresses.map((address) => electrumClient
        .getListUnspentWithAddress(address.address, network)
        .then((unspent) => unspent.map((unspent) {
              try {
                return BitcoinUnspent.fromJSON(address, unspent);
              } catch (_) {
                return null;
              }
            }).whereNotNull())));
    unspentCoins = unspent.expand((e) => e).toList();
    unspentCoins.forEach((coin) async {
      final tx = await fetchTransactionInfo(hash: coin.hash, height: 0);
      coin.isChange = tx?.direction == TransactionDirection.outgoing;
    });

    if (unspentCoinsInfo.isEmpty) {
      unspentCoins.forEach((coin) => _addCoinInfo(coin));
      return;
    }

    if (unspentCoins.isNotEmpty) {
      unspentCoins.forEach((coin) {
        final coinInfoList = unspentCoinsInfo.values.where((element) =>
            element.walletId.contains(id) &&
            element.hash.contains(coin.hash) &&
            element.vout == coin.vout);

        if (coinInfoList.isNotEmpty) {
          final coinInfo = coinInfoList.first;

          coin.isFrozen = coinInfo.isFrozen;
          coin.isSending = coinInfo.isSending;
          coin.note = coinInfo.note;
        } else {
          _addCoinInfo(coin);
        }
      });
    }

    await _refreshUnspentCoinsInfo();
  }

  Future<void> _addCoinInfo(BitcoinUnspent coin) async {
    final newInfo = UnspentCoinsInfo(
      walletId: id,
      hash: coin.hash,
      isFrozen: coin.isFrozen,
      isSending: coin.isSending,
      noteRaw: coin.note,
      address: coin.bitcoinAddressRecord.address,
      value: coin.value,
      vout: coin.vout,
      isChange: coin.isChange,
    );

    await unspentCoinsInfo.add(newInfo);
  }

  Future<void> _refreshUnspentCoinsInfo() async {
    try {
      final List<dynamic> keys = <dynamic>[];
      final currentWalletUnspentCoins =
          unspentCoinsInfo.values.where((element) => element.walletId.contains(id));

      if (currentWalletUnspentCoins.isNotEmpty) {
        currentWalletUnspentCoins.forEach((element) {
          final existUnspentCoins = unspentCoins
              .where((coin) => element.hash.contains(coin.hash) && element.vout == coin.vout);

          if (existUnspentCoins.isEmpty) {
            keys.add(element.key);
          }
        });
      }

      if (keys.isNotEmpty) {
        await unspentCoinsInfo.deleteAll(keys);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  Future<ElectrumTransactionBundle> getTransactionExpanded(
      {required String hash, required int height}) async {
    String transactionHex;
    int? time;
    int confirmations = 0;
    if (network == BitcoinNetwork.mainnet) {
      final verboseTransaction = await electrumClient.getTransactionRaw(hash: hash);

      transactionHex = verboseTransaction as String;
      time = verboseTransaction['time'] as int?;
      confirmations = verboseTransaction['confirmations'] as int? ?? 0;
    } else {
      // Testnet public electrum server does not support verbose transaction fetching
      transactionHex = await electrumClient.getTransactionHex(hash: hash);

      final status = json.decode(
          (await http.get(Uri.parse("https://blockstream.info/testnet/api/tx/$hash/status"))).body);

      time = status["block_time"] as int?;
      final tip = await electrumClient.getCurrentBlockChainTip() ?? 0;
      confirmations = tip - (status["block_height"] as int? ?? 0);
    }

    final original = bitcoin_base.BtcTransaction.fromRaw(transactionHex);
    final ins = <bitcoin_base.BtcTransaction>[];

    for (final vin in original.inputs) {
      try {
        final id = HEX.encode(HEX.decode(vin.txId).reversed.toList());
        final txHex = await electrumClient.getTransactionHex(hash: id);
        final tx = bitcoin_base.BtcTransaction.fromRaw(txHex);
        ins.add(tx);
      } catch (_) {
        ins.add(bitcoin_base.BtcTransaction.fromRaw(
          await electrumClient.getTransactionHex(hash: vin.txId),
        ));
      }
    }

    return ElectrumTransactionBundle(original, ins: ins, time: time, confirmations: confirmations);
  }

  Future<ElectrumTransactionInfo?> fetchTransactionInfo(
      {required String hash, required int height}) async {
    try {
      final tx = await getTransactionExpanded(hash: hash, height: height);
      final addresses = walletAddresses.allAddresses.map((addr) => addr.address).toSet();
      return ElectrumTransactionInfo.fromElectrumBundle(tx, walletInfo.type, network,
          addresses: addresses, height: height);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, ElectrumTransactionInfo>> fetchTransactions() async {
    final addressHashes = <String, BitcoinAddressRecord>{};
    final normalizedHistories = <Map<String, dynamic>>[];
    final newTxCounts = <String, int>{};

    walletAddresses.allAddresses.forEach((addressRecord) {
      final sh = scriptHash(addressRecord.address, network: network);
      addressHashes[sh] = addressRecord;
      newTxCounts[sh] = 0;
    });

    try {
      final histories = addressHashes.keys.map((scriptHash) =>
          electrumClient.getHistory(scriptHash).then((history) => {scriptHash: history}));
      final historyResults = await Future.wait(histories);

      historyResults.forEach((history) {
        history.entries.forEach((historyItem) {
          if (historyItem.value.isNotEmpty) {
            final address = addressHashes[historyItem.key];
            address?.setAsUsed();
            newTxCounts[historyItem.key] = historyItem.value.length;
            normalizedHistories.addAll(historyItem.value);
          }
        });
      });

      for (var sh in addressHashes.keys) {
        var balanceData = await electrumClient.getBalance(sh);
        var addressRecord = addressHashes[sh];
        if (addressRecord != null) {
          addressRecord.balance = balanceData['confirmed'] as int? ?? 0;
        }
      }

      addressHashes.forEach((sh, addressRecord) {
        addressRecord.txCount = newTxCounts[sh] ?? 0;
      });

      final historiesWithDetails = await Future.wait(normalizedHistories.map((transaction) {
        try {
          return fetchTransactionInfo(
              hash: transaction['tx_hash'] as String, height: transaction['height'] as int);
        } catch (_) {
          return Future.value(null);
        }
      }));

      return historiesWithDetails.fold<Map<String, ElectrumTransactionInfo>>(
          <String, ElectrumTransactionInfo>{}, (acc, tx) {
        if (tx == null) {
          return acc;
        }
        acc[tx.id] = acc[tx.id]?.updated(tx) ?? tx;
        return acc;
      });
    } catch (e) {
      print(e.toString());
      return {};
    }
  }

  Future<void> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      walletAddresses.updateReceiveAddresses();
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
      _isTransactionUpdating = false;
    }
  }

  void _subscribeForUpdates() {
    scriptHashes.forEach((sh) async {
      await _scripthashesUpdateSubject[sh]?.close();
      _scripthashesUpdateSubject[sh] = electrumClient.scripthashUpdate(sh);
      _scripthashesUpdateSubject[sh]?.listen((event) async {
        try {
          await updateUnspent();
          await updateBalance();
          await updateTransactions();
        } catch (e, s) {
          print(e.toString());
          _onError?.call(FlutterErrorDetails(
            exception: e,
            stack: s,
            library: this.runtimeType.toString(),
          ));
        }
      });
    });
  }

  Future<ElectrumBalance> _fetchBalances() async {
    final addresses = walletAddresses.allAddresses.toList();
    final balanceFutures = <Future<Map<String, dynamic>>>[];
    for (var i = 0; i < addresses.length; i++) {
      final addressRecord = addresses[i];
      final sh = scriptHash(addressRecord.address, network: network);
      final balanceFuture = electrumClient.getBalance(sh);
      balanceFutures.add(balanceFuture);
    }

    var totalFrozen = 0;
    unspentCoinsInfo.values.forEach((info) {
      unspentCoins.forEach((element) {
        if (element.hash == info.hash &&
            element.vout == info.vout &&
            info.isFrozen &&
            element.bitcoinAddressRecord.address == info.address &&
            element.value == info.value) {
          totalFrozen += element.value;
        }
      });
    });

    final balances = await Future.wait(balanceFutures);
    var totalConfirmed = 0;
    var totalUnconfirmed = 0;

    for (var i = 0; i < balances.length; i++) {
      final addressRecord = addresses[i];
      final balance = balances[i];
      final confirmed = balance['confirmed'] as int? ?? 0;
      final unconfirmed = balance['unconfirmed'] as int? ?? 0;
      totalConfirmed += confirmed;
      totalUnconfirmed += unconfirmed;

      if (confirmed > 0 || unconfirmed > 0) {
        addressRecord.setAsUsed();
      }
    }

    return ElectrumBalance(
        confirmed: totalConfirmed, unconfirmed: totalUnconfirmed, frozen: totalFrozen);
  }

  Future<void> updateBalance() async {
    balance[currency] = await _fetchBalances();
    await save();
  }

  String getChangeAddress() {
    const minCountOfHiddenAddresses = 5;
    final random = Random();
    var addresses = walletAddresses.allAddresses.where((addr) => addr.isHidden).toList();

    if (addresses.length < minCountOfHiddenAddresses) {
      addresses = walletAddresses.allAddresses.toList();
    }

    return addresses[random.nextInt(addresses.length)].address;
  }

  @override
  void setExceptionHandler(void Function(FlutterErrorDetails) onError) => _onError = onError;

  @override
  String signMessage(String message, {String? address = null}) {
    final index = address != null
        ? walletAddresses.allAddresses.firstWhere((element) => element.address == address).index
        : null;
    final HD = index == null ? hd : hd.derive(index);
    return base64Encode(HD.signMessage(message));
  }
}
// TODO: contact addresses
// TODO: select change address
