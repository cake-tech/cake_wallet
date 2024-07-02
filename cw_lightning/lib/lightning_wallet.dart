import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_lightning/lightning_balance.dart';
import 'package:cw_lightning/lightning_transaction_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_core/wallet_info.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_lightning/.secrets.g.dart' as secrets;
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:bip39/bip39.dart' as bip39;

part 'lightning_wallet.g.dart';

class LightningWallet = LightningWalletBase with _$LightningWallet;

abstract class LightningWalletBase extends ElectrumWallet with Store {
  bool _isTransactionUpdating;

  @override
  @observable
  SyncStatus syncStatus;

  LightningWalletBase({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Uint8List seedBytes,
    String? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    LightningBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  })  : _isTransactionUpdating = false,
        syncStatus = NotConnectedSyncStatus(),
        _balance = ObservableMap<CryptoCurrency, LightningBalance>(),
        mnemonic = mnemonic,
        seedBytes = seedBytes,
        super(
          password: password,
          walletInfo: walletInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          networkType: bitcoin.bitcoin,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          currency: CryptoCurrency.btcln,
        ) {
    _balance[CryptoCurrency.btcln] =
        initialBalance ?? LightningBalance(confirmed: 0, unconfirmed: 0, frozen: 0);
    String derivationPath = walletInfo.derivationInfo!.derivationPath!;
    String sideDerivationPath = derivationPath.substring(0, derivationPath.length - 1) + "1";
    final hd = bitcoin.HDWallet.fromSeed(seedBytes, network: networkType);
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHd: hd.derivePath(derivationPath),
      sideHd: hd.derivePath(sideDerivationPath),
      network: network,
    );

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  late final ObservableMap<CryptoCurrency, LightningBalance> _balance;
  StreamSubscription<List<Payment>>? _paymentsSub;
  StreamSubscription<NodeState?>? _nodeStateSub;
  StreamSubscription<LogEntry>? _logStream;

  late final Uint8List seedBytes;
  String mnemonic;
  @override
  String get seed => mnemonic;

  @override
  @computed
  ObservableMap<CryptoCurrency, LightningBalance> get balance => _balance;

  static Future<Uint8List> toSeedBytes(String mnemonic) async {
    // electrum:
    // if (validateMnemonic(mnemonic)) {
    // return await mnemonicToSeedBytes(mnemonic);
    // bip39:
    // } else if (bip39.validateMnemonic(mnemonic)) {
    return await bip39.mnemonicToSeed(mnemonic);
    // } else {
    //   throw Exception("Invalid mnemonic!");
    // }
  }

  static Future<LightningWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      String? addressPageType,
      List<BitcoinAddressRecord>? initialAddresses,
      LightningBalance? initialBalance,
      Map<String, int>? initialRegularAddressIndex,
      Map<String, int>? initialChangeAddressIndex}) async {
    return LightningWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      seedBytes: await toSeedBytes(mnemonic),
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: addressPageType,
    );
  }

  static Future<LightningWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
  }) async {
    final snp =
        await ElectrumWalletSnapshot.load(name, walletInfo.type, password, BitcoinNetwork.mainnet);

    return LightningWallet(
      mnemonic: snp.mnemonic!,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp.addresses,
      initialBalance: LightningBalance(
        confirmed: snp.balance.confirmed,
        unconfirmed: snp.balance.unconfirmed,
        frozen: snp.balance.frozen,
      ),
      seedBytes: await toSeedBytes(snp.mnemonic!),
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      addressPageType: snp.addressPageType,
    );
  }

  Future<void> _handleNodeState(NodeState? nodeState) async {
    if (nodeState == null) return;
    _balance[CryptoCurrency.btcln] = LightningBalance(
      confirmed: nodeState.maxPayableMsat ~/ 1000,
      unconfirmed: nodeState.maxReceivableMsat ~/ 1000,
      frozen: 0,
    );
  }

  Future<void> _handlePayments(List<Payment> payments) async {
    _isTransactionUpdating = true;
    final txs = convertToTxInfo(payments);
    transactionHistory.addMany(txs);
    _isTransactionUpdating = false;
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    await stopBreez(true);
    await super.renameWalletFiles(newWalletName);
    await setupBreez(seedBytes);
  }

  void _logSdkEntries(LogEntry entry) {
    switch (entry.level) {
      case "ERROR":
      case "WARN":
      case "INFO":
        // case "DEBUG":
        // case "TRACE":
        print("BREEZ:${entry.level}: ${entry.line}");
        break;
    }
  }

  Future<void> setupBreez(Uint8List seedBytes) async {
    final sdk = await BreezSDK();
    _logStream?.cancel();
    _logStream = sdk.logStream.listen(_logSdkEntries);

    try {
      if (!(await sdk.isInitialized())) {
        sdk.initialize();
      }
    } catch (e) {
      print("Error initializing Breez: $e");
      return;
    }

    GreenlightCredentials greenlightCredentials = GreenlightCredentials(
      developerKey: base64.decode(secrets.greenlightKey),
      developerCert: base64.decode(secrets.greenlightCert),
    );

    NodeConfig breezNodeConfig = NodeConfig.greenlight(
      config: GreenlightNodeConfig(
        partnerCredentials: greenlightCredentials,
        inviteCode: null,
      ),
    );
    Config breezConfig = await sdk.defaultConfig(
      envType: EnvironmentType.Production,
      apiKey: secrets.breezApiKey,
      nodeConfig: breezNodeConfig,
    );

    String workingDir = await pathForWalletDir(name: walletInfo.name, type: type);
    workingDir = "$workingDir/breez/";

    new Directory(workingDir).createSync(recursive: true);
    breezConfig = breezConfig.copyWith(workingDir: workingDir);

    // disconnect if already connected
    try {
      if (await sdk.isInitialized()) {
        await sdk.disconnect();
      }
    } catch (e, s) {
      print("ERROR disconnecting from Breez: $e\n$s");
    }

    try {
      await sdk.connect(
        req: ConnectRequest(
          config: breezConfig,
          seed: seedBytes,
        ),
      );
    } catch (e, s) {
      print("Error connecting to Breez: $e\n$s");
    }

    await _nodeStateSub?.cancel();
    _nodeStateSub = sdk.nodeStateStream.listen((event) {
      _handleNodeState(event);
    });
    await _handleNodeState(await sdk.nodeInfo());

    await _paymentsSub?.cancel();
    _paymentsSub = sdk.paymentsStream.listen((List<Payment> payments) {
      _handlePayments(payments);
    });
    await _handlePayments(await sdk.listPayments(req: ListPaymentsRequest()));

    // print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    // print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    // print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    // print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    // print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    // await BreezSDK().rescanSwaps();  
    // List<SwapInfo> refundables = await BreezSDK().listRefundables();
    // for (var refundable in refundables) {
    //   print(refundable.bitcoinAddress);
    // }
    // SwapInfo? swapInfo = await BreezSDK().inProgressSwap();
    // print(swapInfo);

    print("initialized breez: ${(await sdk.isInitialized())}");
  }

  Future<void> stopBreez(bool disconnect) async {
    if (disconnect) {
      final sdk = await BreezSDK();
      if (await sdk.isInitialized()) {
        await sdk.disconnect();
      }
    }
    await _nodeStateSub?.cancel();
    await _paymentsSub?.cancel();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await updateTransactions();
      syncStatus = SyncedSyncStatus();
    } catch (e) {
      print(e);
      syncStatus = FailedSyncStatus();
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String password) {
    throw UnimplementedError("changePassword");
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();
      await updateTransactions();
      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      print(e);
      syncStatus = FailedSyncStatus();
    }
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    throw UnimplementedError("createTransaction");
  }

  Future<bool> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return false;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
      return true;
    } catch (_) {
      _isTransactionUpdating = false;
      return false;
    }
  }

  Map<String, LightningTransactionInfo> convertToTxInfo(List<Payment> payments) {
    Map<String, LightningTransactionInfo> transactions = {};

    for (Payment tx in payments) {
      if (tx.paymentType == PaymentType.ClosedChannel) {
        continue;
      }
      bool isSend = tx.paymentType == PaymentType.Sent;
      transactions[tx.id] = LightningTransactionInfo(
        isPending: false,
        id: tx.id,
        amount: tx.amountMsat ~/ 1000,
        fee: tx.feeMsat ~/ 1000,
        date: DateTime.fromMillisecondsSinceEpoch(tx.paymentTime * 1000),
        direction: isSend ? TransactionDirection.outgoing : TransactionDirection.incoming,
      );
    }
    return transactions;
  }

  @override
  Future<Map<String, LightningTransactionInfo>> fetchTransactions() async {
    final sdk = await BreezSDK();

    final payments = await sdk.listPayments(req: ListPaymentsRequest());
    final transactions = convertToTxInfo(payments);

    return transactions;
  }

  @override
  Future<void> rescan({
    required int height,
    int? chainTip,
    ScanData? scanData,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    updateTransactions();
  }

  @override
  Future<void> init() async {
    super.init();
    // initialize breez:
    try {
      // final seedBytes = await bip39.mnemonicToSeed(mnemonic);
      await setupBreez(seedBytes);
    } catch (e) {
      print("Error initializing Breez: $e");
    }
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': walletAddresses.currentReceiveAddressIndexByType,
        'change_address_index': walletAddresses.currentChangeAddressIndexByType,
        'addresses': walletAddresses.allAddresses.map((addr) => addr.toJSON()).toList(),
        'address_page_type': walletInfo.addressPageType == null
            ? SegwitAddresType.p2wpkh.toString()
            : walletInfo.addressPageType.toString(),
        'balance': balance[currency]?.toJSON(),
        'network_type': network == BitcoinNetwork.testnet ? 'testnet' : 'mainnet',
      });

  Future<void> updateBalance() async {
    // balance is updated automatically
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  @override
  Future<void> close({bool? switchingToSameWalletType}) async {
    try {
      await electrumClient.close();
    } catch (_) {}
    try {
      bool shouldDisconnect = switchingToSameWalletType == null || !switchingToSameWalletType;
      await stopBreez(shouldDisconnect);
    } catch (e, s) {
      print("Error stopping breez: $e\n$s");
    }
  }
}