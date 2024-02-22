import 'dart:convert';
import 'dart:io';

import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_wallet_keys.dart';
import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_lightning/lightning_balance.dart';
import 'package:cw_lightning/lightning_transaction_history.dart';
import 'package:cw_lightning/lightning_transaction_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cw_lightning/.secrets.g.dart' as secrets;
import 'package:cw_core/wallet_base.dart';

part 'lightning_wallet.g.dart';

class LightningWallet = LightningWalletBase with _$LightningWallet;

abstract class LightningWalletBase
    extends WalletBase<LightningBalance, LightningTransactionHistory, LightningTransactionInfo>
    with Store {
  final bitcoin.HDWallet hd;
  final String mnemonic;
  String _password;
  bool _isTransactionUpdating;
  late ElectrumClient electrumClient;

  @override
  @observable
  late ObservableMap<CryptoCurrency, LightningBalance> balance;

  @override
  late ElectrumWalletAddresses walletAddresses;

  bitcoin.NetworkType networkType = bitcoin.bitcoin;

  @override
  BitcoinWalletKeys get keys =>
      BitcoinWalletKeys(wif: hd.wif!, privateKey: hd.privKey!, publicKey: hd.pubKey!);

  @override
  @observable
  SyncStatus syncStatus;

  LightningWalletBase(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required Uint8List seedBytes,
      ElectrumClient? electrumClient,
      List<BitcoinAddressRecord>? initialAddresses,
      LightningBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0})
      : hd = bitcoin.HDWallet.fromSeed(seedBytes, network: bitcoin.bitcoin).derivePath("m/0'/0"),
        syncStatus = NotConnectedSyncStatus(),
        mnemonic = mnemonic,
        _password = password,
        _isTransactionUpdating = false,
        balance = ObservableMap<CryptoCurrency, LightningBalance>.of({
          CryptoCurrency.btc:
              initialBalance ?? const LightningBalance(confirmed: 0, unconfirmed: 0, frozen: 0)
        }),
        super(walletInfo) {
    transactionHistory = LightningTransactionHistory(walletInfo: walletInfo, password: password);
    walletAddresses = BitcoinWalletAddresses(walletInfo,
        electrumClient: electrumClient ?? ElectrumClient(),
        initialAddresses: initialAddresses,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        mainHd: hd,
        sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/1"),
        networkType: networkType);

    this.electrumClient = electrumClient ?? ElectrumClient();

    // initialize breeze:
    try {
      setupBreez(seedBytes);
    } catch (e) {
      print("Error initializing Breez: $e");
    }

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  static Future<LightningWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      List<BitcoinAddressRecord>? initialAddresses,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0}) async {
    return LightningWallet(
        mnemonic: mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: initialAddresses,
        seedBytes: await mnemonicToSeedBytes(mnemonic),
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex);
  }

  static Future<LightningWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
  }) async {
    final snp = await ElectrumWallletSnapshot.load(name, walletInfo.type, password);
    return LightningWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp.addresses,
        seedBytes: await mnemonicToSeedBytes(snp.mnemonic),
        initialRegularAddressIndex: snp.regularAddressIndex,
        initialChangeAddressIndex: snp.changeAddressIndex);
  }

  Future<void> setupBreez(Uint8List seedBytes) async {
    // Initialize SDK logs listener
    final sdk = BreezSDK();
    try {
      sdk.initialize();
    } catch (e) {
      print("Error initializing Breez: $e");
    }

    NodeConfig breezNodeConfig = NodeConfig.greenlight(
      config: GreenlightNodeConfig(
        partnerCredentials: null,
        inviteCode: secrets.breezInviteCode,
      ),
    );
    Config breezConfig = await sdk.defaultConfig(
      envType: EnvironmentType.Production,
      apiKey: secrets.breezApiKey,
      nodeConfig: breezNodeConfig,
    );

    // Customize the config object according to your needs
    String workingDir = (await getApplicationDocumentsDirectory()).path;
    workingDir = "$workingDir/wallets/lightning/${walletInfo.name}/breez/";
    new Directory(workingDir).createSync(recursive: true);
    breezConfig = breezConfig.copyWith(workingDir: workingDir);

    try {
      // disconnect if already connected
      await sdk.disconnect();
    } catch (_) {}

    try {
      await sdk.connect(config: breezConfig, seed: seedBytes);
    } catch (e) {
      print("Error connecting to Breez: $e");
    }

    sdk.nodeStateStream.listen((event) {
      if (event == null) return;
      balance[CryptoCurrency.btc] = LightningBalance(
        confirmed: event.maxPayableMsat ~/ 1000,
        unconfirmed: event.maxReceivableMsat ~/ 1000,
        frozen: 0,
      );
    });

    sdk.paymentsStream.listen((payments) {
      _isTransactionUpdating = true;
      print("payment event: $payments");
      var txs = convertToTxInfo(payments);
      transactionHistory.addMany(txs);
      _isTransactionUpdating = false;
    });

    print("initialized breez: ${(await sdk.isInitialized())}");
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    throw UnimplementedError("calculateEstimatedFee");
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

  @override
  void close() {}

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
        WalletType.lightning,
        isPending: false,
        id: tx.id,
        amount: tx.amountMsat ~/ 1000,
        fee: tx.feeMsat,
        date: DateTime.fromMillisecondsSinceEpoch(tx.paymentTime * 1000),
        height: tx.paymentTime,
        direction: isSend ? TransactionDirection.outgoing : TransactionDirection.incoming,
        confirmations: 1,
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
  Future<void> rescan({required int height}) async {
    updateTransactions();
  }

  Future<void> init() async {
    await walletAddresses.init();
    await transactionHistory.init();
    await save();
  }

  String toJSON() => json.encode({
        'mnemonic': mnemonic,
        'account_index': walletAddresses.currentReceiveAddressIndex.toString(),
        'change_address_index': walletAddresses.currentChangeAddressIndex.toString(),
        'addresses': walletAddresses.addresses.map((addr) => addr.toJSON()).toList(),
        'balance': balance[currency]?.toJSON()
      });

  @override
  Future<void> save() async {
    final path = await makePath();
    await write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  Future<void> updateBalance() async {
    // balance[currency] = await _fetchBalances();
    await save();
  }

  @override
  String get seed => mnemonic;

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  // String toJSON() => json.encode({
  //       'seedKey': _hexSeed,
  //       'mnemonic': _mnemonic,
  //       'currentBalance': balance[currency]?.currentBalance.toString() ?? "0",
  //       'receivableBalance': balance[currency]?.receivableBalance.toString() ?? "0",
  //       'derivationType': _derivationType.toString()
  //     });

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
}
