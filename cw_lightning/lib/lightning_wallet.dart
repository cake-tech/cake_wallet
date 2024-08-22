import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bitcoin_base/bitcoin_base.dart';
// import 'package:breez_sdk/breez_sdk.dart';
// import 'package:breez_sdk/bridge_generated.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_lightning/lightning_balance.dart';
import 'package:cw_lightning/lightning_transaction_info.dart';
import 'package:cw_lightning/lightning_transaction_priority.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_lightning/.secrets.g.dart' as secrets;
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:ldk_node/ldk_node.dart' as ldk;

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
    required EncryptionFileUtils encryptionFileUtils,
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
          network: BitcoinNetwork.mainnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          encryptionFileUtils: encryptionFileUtils,
          currency: CryptoCurrency.btcln,
        ) {
    _balance[CryptoCurrency.btcln] =
        initialBalance ?? LightningBalance(confirmed: 0, unconfirmed: 0, frozen: 0);
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHd: super.hd,
      sideHd: super.accountHD.childKey(Bip32KeyIndex(1)),
      network: network,
    );

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  late final ObservableMap<CryptoCurrency, LightningBalance> _balance;
  // StreamSubscription<List<Payment>>? _paymentsSub;
  // StreamSubscription<NodeState?>? _nodeStateSub;
  // StreamSubscription<LogEntry>? _logStream;
  // StreamSubscription<InvoicePaidDetails>? _invoiceSub;
  // late final BreezSDK _sdk;
  late ldk.Builder _builder;
  ldk.Node? _node;

  late final Uint8List seedBytes;
  String mnemonic;
  @override
  String get seed => mnemonic;

  Map<String, int> incomingPayments = <String, int>{};

  // RecommendedFees recommendedFees = RecommendedFees(
  //   economyFee: 0,
  //   fastestFee: 0,
  //   halfHourFee: 0,
  //   hourFee: 0,
  //   minimumFee: 0,
  // );

  @override
  @computed
  ObservableMap<CryptoCurrency, LightningBalance> get balance => _balance;

  static Future<LightningWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required EncryptionFileUtils encryptionFileUtils,
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
      seedBytes: await universalMnemonictoSeedBytes(
        mnemonic,
        derivationType: walletInfo.derivationInfo?.derivationType,
      ),
      encryptionFileUtils: encryptionFileUtils,
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
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final snp = await ElectrumWalletSnapshot.load(
      encryptionFileUtils,
      name,
      walletInfo.type,
      password,
      BitcoinNetwork.mainnet,
    );

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
      seedBytes: await universalMnemonictoSeedBytes(
        snp.mnemonic!,
        derivationType: walletInfo.derivationInfo?.derivationType,
      ),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      addressPageType: snp.addressPageType,
    );
  }

  // Future<void> _handleNodeState(NodeState? nodeState) async {
  //   if (nodeState == null) return;
  //   _balance[CryptoCurrency.btcln] = LightningBalance(
  //     confirmed: nodeState.maxPayableMsat ~/ 1000,
  //     unconfirmed: nodeState.maxReceivableMsat ~/ 1000,
  //     frozen: nodeState.onchainBalanceMsat ~/ 1000,
  //   );
  // }

  // Future<void> _handlePayments(List<Payment> payments) async {
  //   _isTransactionUpdating = true;
  //   final txs = convertToTxInfo(payments);
  //   await alertIncomingTxs(txs);
  //   transactionHistory.addMany(txs);
  //   _isTransactionUpdating = false;
  //   if (txs.isNotEmpty) {
  //     await updateBalance();
  //   }
  // }

  // Future<void> _handleInvoicePaid(InvoicePaidDetails details) async {
  //   _isTransactionUpdating = true;

  //   if (details.payment == null) {
  //     return;
  //   }

  //   final txs = convertToTxInfo([details.payment!]);
  //   await alertIncomingTxs(txs);
  //   transactionHistory.addMany(txs);
  //   _isTransactionUpdating = false;
  //   if (txs.isNotEmpty) {
  //     await updateBalance();
  //   }
  // }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    await stopLightningNode(true);
    await super.renameWalletFiles(newWalletName);
    await setupLightningNode(mnemonic);
  }

  totalOnchainBalanceSats() async {
    final balance = await _node?.listBalances();
    if (balance == null) {
      return;
    }
    _balance[CryptoCurrency.btcln] = LightningBalance(
      confirmed: balance.spendableOnchainBalanceSats.toInt(),
      unconfirmed: (balance.totalOnchainBalanceSats - balance.spendableOnchainBalanceSats).toInt(),
      frozen: balance.totalOnchainBalanceSats.toInt(),
    );
    print("wallet balance: ${balance.totalOnchainBalanceSats}");
    print("wallet spendable balance: ${balance.spendableOnchainBalanceSats}");
  }

  syncWallets() async {
    await _node?.syncWallets();
    print("wallet syncing complete!");
  }

  listChannels() async {
    final res = await _node?.listChannels();
    if (res == null) {
      return;
    }
    if (res.isNotEmpty) {
      print("======Channels========");
      for (var e in res) {
        print("nodeId: ${(await _node!.nodeId()).hex}");
        print("userChannelId: ${e.userChannelId.data}");
        print("confirmations required: ${e.confirmationsRequired}");
        print("isChannelReady: ${e.isChannelReady}");
        print("isUsable: ${e.isUsable}");
        print("outboundCapacityMsat: ${e.outboundCapacityMsat}");
      }
    }
  }

  listPaymentsWithFilter(bool printPayments) async {
    // final res =
    //     await aliceNode.listPaymentsWithFilter(paymentDirection: ldk.PaymentDirection.outbound);
    // if (res.isNotEmpty) {
    //   if (printPayments) {
    //     if (kDebugMode) {
    //       print("======Payments========");
    //       for (var e in res) {
    //         print("amountMsat: ${e.amountMsat}");
    //         print("paymentId: ${e.id.field0}");
    //         print("status: ${e.status.name}");
    //       }
    //     }
    //   }
    //   return res.last;
    // } else {
    //   return null;
    // }
  }

  removeLastPayment() async {
    // final lastPayment = await listPaymentsWithFilter(false);
    // if (lastPayment != null) {
    //   final _ = await aliceNode.removePayment(paymentId: lastPayment.id);
    //   setState(() {
    //     displayText = "${lastPayment.hash.internal} removed";
    //   });
    // }
  }

  Future<String> newOnchainAddress() async {
    if (_node == null) {
      return "";
    }
    final payment = await _node!.onChainPayment();
    final address = await payment.newAddress();
    return address.s;
  }

  listeningAddress() async {
    // final alice = await aliceNode.listeningAddresses();
    // final bob = await bobNode.listeningAddresses();

    // setState(() {
    //   bobAddr = bob!.first;
    // });
    // if (kDebugMode) {
    //   print("alice's listeningAddress : ${alice!.first.toString()}");
    //   print("bob's listeningAddress: ${bob!.first.toString()}");
    // }
  }

  closeChannel() async {
    // await aliceNode.closeChannel(
    //     userChannelId: userChannelId!,
    //     counterpartyNodeId: ldk.PublicKey(
    //       hex: '02465ed5be53d04fde66c9418ff14a5f2267723810176c9212b722e542dc1afb1b',
    //     ));
  }

  connectOpenChannel() async {
    // final funding_amount_sat = 80000;
    // final push_msat = (funding_amount_sat / 2) * 1000;
    // userChannelId = await aliceNode.connectOpenChannel(
    //     channelAmountSats: BigInt.from(funding_amount_sat),
    //     announceChannel: true,
    //     socketAddress: ldk.SocketAddress.hostname(
    //       addr: '45.79.52.207',
    //       port: 9735,
    //     ),
    //     pushToCounterpartyMsat: BigInt.from(push_msat),
    //     nodeId: ldk.PublicKey(
    //       hex: '02465ed5be53d04fde66c9418ff14a5f2267723810176c9212b722e542dc1afb1b',
    //     ));
  }

  receiveAndSendPayments() async {
    // final bobBolt11Handler = await bobNode.bolt11Payment();
    // final aliceBolt11Handler = await aliceNode.bolt11Payment();
    // // Bob doesn't have a channel yet, so he can't receive normal payments,
    // //  but he can receive payments via JIT channels through an LSP configured
    // //  in its node.
    // invoice = await bobBolt11Handler.receiveViaJitChannel(
    //     amountMsat: BigInt.from(25000 * 1000), description: 'asdf', expirySecs: 9217);
    // print(invoice!.signedRawInvoice);
    // setState(() {
    //   displayText = invoice!.signedRawInvoice;
    // });
    // final paymentId = await aliceBolt11Handler.send(invoice: invoice!);
    // final res = await aliceNode.payment(paymentId: paymentId);
    // setState(() {
    //   displayText = "Payment status: ${res?.status.name}\n PaymentId: ${res?.id.field0}";
    // });
  }

  stop() async {
    // await bobNode.stop();
    // await aliceNode.stop();
  }

  Future handleEvent(ldk.Node node) async {
    final res = await node.nextEvent();
    res?.map(paymentSuccessful: (e) {
      if (kDebugMode) {
        print("paymentSuccessful: ${e.paymentHash.data}");
      }
    }, paymentFailed: (e) {
      if (kDebugMode) {
        print("paymentFailed: ${e.paymentHash.data}");
      }
    }, paymentReceived: (e) {
      if (kDebugMode) {
        print("paymentReceived: ${e.paymentHash.data}");
      }
    }, channelReady: (e) {
      if (kDebugMode) {
        print("channelReady: ${e.channelId.data}, userChannelId: ${e.userChannelId.data}");
      }
    }, channelClosed: (e) {
      if (kDebugMode) {
        print("channelClosed: ${e.channelId.data}, userChannelId: ${e.userChannelId.data}");
      }
    }, channelPending: (e) {
      if (kDebugMode) {
        print("channelClosed: ${e.channelId.data}, userChannelId: ${e.userChannelId.data}");
      }
    }, paymentClaimable: (e) {
      if (kDebugMode) {
        print(
            "paymentId: ${e.paymentId.field0.toString()}, claimableAmountMsat: ${e.claimableAmountMsat}, userChannelId: ${e.claimDeadline}");
      }
    });
    await node.eventHandled();
  }

  Future<void> startNode(ldk.Node node) async {
    try {
      node.start();
    } on ldk.NodeException catch (e) {
      print(e.toString());
    }
  }

  Future<ldk.Builder> createBuilder(String mnemonic) async {
    String workingDir = await pathForWalletDir(name: walletInfo.name, type: type);
    workingDir = "$workingDir/ldk/";
    new Directory(workingDir).createSync(recursive: true);

    String esploraUrl = "https://mutinynet.ltbl.io/api";

    ldk.SocketAddress address = ldk.SocketAddress.hostname(addr: "0.0.0.0", port: 3003);

    return ldk.Builder.mutinynet()
        .setEntropyBip39Mnemonic(mnemonic: ldk.Mnemonic(seedPhrase: mnemonic))
        .setEsploraServer(esploraUrl)
        .setStorageDirPath(workingDir)
        .setListeningAddresses([address]);
  }

  Future<void> setupLightningNode(String mnemonic) async {
    // _sdk = await BreezSDK();
    // await _logStream?.cancel();
    // _logStream = _sdk.logStream.listen(_logSdkEntries);

    // try {
    //   if (!(await _sdk.isInitialized())) {
    //     _sdk.initialize();
    //   }
    // } catch (e) {
    //   print("Error initializing Breez: $e");
    //   return;
    // }

    if (_node != null) {
      await _node?.stop();
    }

    _builder = await createBuilder(mnemonic);
    _node = await _builder.build();
    await startNode(_node!);
    print("node started!");

    // // disconnect if already connected
    // try {
    //   if (await _sdk.isInitialized()) {
    //     await _sdk.disconnect();
    //   }
    // } catch (e, s) {
    //   print("ERROR disconnecting from Breez: $e\n$s");
    // }

    // try {
    //   await _sdk.connect(
    //     req: ConnectRequest(
    //       config: breezConfig,
    //       seed: seedBytes,
    //     ),
    //   );
    // } catch (e, s) {
    //   print("Error connecting to Breez: $e\n$s");
    // }

    // await _nodeStateSub?.cancel();
    // _nodeStateSub = _sdk.nodeStateStream.listen((event) {
    //   _handleNodeState(event);
    // });
    // await _handleNodeState(await _sdk.nodeInfo());

    // await _paymentsSub?.cancel();
    // _paymentsSub = _sdk.paymentsStream.listen((List<Payment> payments) {
    //   _handlePayments(payments);
    // });
    // await _handlePayments(await _sdk.listPayments(req: ListPaymentsRequest()));

    // await _invoiceSub?.cancel();
    // _invoiceSub = _sdk.invoicePaidStream.listen((InvoicePaidDetails details) {
    //   _handleInvoicePaid(details);
    // });

    // print("initialized breez: ${(await _sdk.isInitialized())}");
  }

  Future<void> stopLightningNode(bool disconnect) async {
    // if (disconnect) {
    //   if (await _sdk.isInitialized()) {
    //     await _sdk.disconnect();
    //   }
    // }
    // await _nodeStateSub?.cancel();
    // await _paymentsSub?.cancel();
    // await _invoiceSub?.cancel();
    // await _logStream?.cancel();
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();
      await updateTransactions();
      await fetchFees();
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
  void _onConnectionStatusChange(bool? isConnected) {
    if (syncStatus is SyncingSyncStatus) return;

    if (isConnected == true && syncStatus is! SyncedSyncStatus) {
      syncStatus = ConnectedSyncStatus();
    } else if (isConnected == false) {
      syncStatus = LostConnectionSyncStatus();
    } else if (isConnected != true && syncStatus is! ConnectingSyncStatus) {
      syncStatus = NotConnectedSyncStatus();
    }
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

  Future<void> alertIncomingTxs(Map<String, LightningTransactionInfo> transactions) async {
    for (var tx in transactions.values) {
      // transaction is a receive that we haven't seen before:
      if (tx.direction == TransactionDirection.incoming &&
          transactionHistory.transactions[tx.id] == null) {
        incomingPayments[tx.id] = tx.amount;
      }
    }
  }

  Future<bool> updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return false;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      await alertIncomingTxs(transactions);
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
      return true;
    } catch (_) {
      _isTransactionUpdating = false;
      return false;
    }
  }

  // Map<String, LightningTransactionInfo> convertToTxInfo(List<Payment> payments) {
  //   Map<String, LightningTransactionInfo> transactions = {};

  //   for (Payment tx in payments) {
  //     bool pending = tx.status == PaymentStatus.Pending;
  //     if (tx.status == PaymentStatus.Complete) {
  //       pending = false;
  //     }

  //     bool isSend =
  //         tx.paymentType == PaymentType.Sent || tx.paymentType == PaymentType.ClosedChannel;
  //     transactions[tx.id] = LightningTransactionInfo(
  //       isPending: pending,
  //       id: tx.id,
  //       amount: tx.amountMsat ~/ 1000,
  //       fee: tx.feeMsat ~/ 1000,
  //       date: DateTime.fromMillisecondsSinceEpoch(tx.paymentTime * 1000),
  //       direction: isSend ? TransactionDirection.outgoing : TransactionDirection.incoming,
  //       isChannelClose: tx.paymentType == PaymentType.ClosedChannel,
  //     );
  //   }
  //   return transactions;
  // }

  @override
  Future<Map<String, LightningTransactionInfo>> fetchTransactions() async {
    // final payments = await _sdk.listPayments(req: ListPaymentsRequest());
    // final transactions = convertToTxInfo(payments);

    // return transactions;
    return {};
  }

  @override
  Future<void> rescan({
    required int height,
    int? chainTip,
    ScanData? scanData,
    bool? doSingleScan,
    bool? usingElectrs,
  }) async {
    await updateTransactions();
  }

  @override
  Future<void> init() async {
    await super.init();
    try {
      await setupLightningNode(mnemonic);
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
    // await _handleNodeState(await _sdk.nodeInfo());
  }

  Future<String> makePath() async => pathForWallet(name: walletInfo.name, type: walletInfo.type);

  @override
  Future<void> close({bool? switchingToSameWalletType}) async {
    try {
      await electrumClient.close();
    } catch (_) {}
    try {
      bool shouldDisconnect = switchingToSameWalletType == null || !switchingToSameWalletType;
      await stopLightningNode(shouldDisconnect);
    } catch (e, s) {
      print("Error stopping breez: $e\n$s");
    }
  }

  Future<int> calculateEstimatedFeeAsync(TransactionPriority? priority, int? amount) async {
    if (priority is LightningTransactionPriority) {
      int feeRate = this.feeRate(priority);
      return getEstimatedFeeWithFeeRate(feeRate, amount);
    }
    return 0;
  }

  Future<int> getEstimatedFeeWithFeeRate(int feeRate, int? amount) async {
    // try {
    //   if (amount == null) {
    //     amount = 0;
    //   }

    //   PrepareOnchainPaymentResponse prepareRes = await _sdk.prepareOnchainPayment(
    //     req: PrepareOnchainPaymentRequest(
    //       amountSat: amount,
    //       amountType: SwapAmountType.Send,
    //       claimTxFeerate: feeRate,
    //     ),
    //   );

    //   print("Sender amount: ${prepareRes.senderAmountSat} sats");
    //   print("Recipient amount: ${prepareRes.recipientAmountSat} sats");
    //   print("Total fees: ${prepareRes.totalFees} sats");
    //   return prepareRes.totalFees;
    // } catch (e) {
    //   print("Error calculating fee: $e");
    //   return 0;
    // }
    return 0;
  }

  @override
  int feeRate(TransactionPriority priority) {
    // try {
    //   if (priority is LightningTransactionPriority) {
    //     switch (priority) {
    //       case LightningTransactionPriority.economy:
    //         return recommendedFees.economyFee;
    //       case LightningTransactionPriority.fastest:
    //         return recommendedFees.fastestFee;
    //       case LightningTransactionPriority.halfhour:
    //         return recommendedFees.halfHourFee;
    //       case LightningTransactionPriority.hour:
    //         return recommendedFees.hourFee;
    //       case LightningTransactionPriority.minimum:
    //         return recommendedFees.minimumFee;
    //       case LightningTransactionPriority.custom:
    //         throw Exception("Use getEstimatedFeeWithFeeRate instead!");
    //     }
    //   }

    //   return 0;
    // } catch (_) {
    //   return 0;
    // }
    return 0;
  }

  Future<void> fetchFees() async {
    // recommendedFees = await _sdk.recommendedFees();
  }
}
