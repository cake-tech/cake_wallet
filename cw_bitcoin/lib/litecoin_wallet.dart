import 'dart:async';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_bitcoin/litecoin_wallet_addresses.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/litecoin_network.dart';
import 'package:cw_mweb/cw_mweb.dart';
import 'package:cw_mweb/mwebd.pb.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;

part 'litecoin_wallet.g.dart';

class LitecoinWallet = LitecoinWalletBase with _$LitecoinWallet;

abstract class LitecoinWalletBase extends ElectrumWallet with Store {
  LitecoinWalletBase({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Uint8List seedBytes,
    String? addressPageType,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) : mwebHd = bitcoin.HDWallet.fromSeed(seedBytes,
            network: litecoinNetwork).derivePath("m/1000'"),
       super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: litecoinNetwork,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            seedBytes: seedBytes,
            currency: CryptoCurrency.ltc) {
    walletAddresses = LitecoinWalletAddresses(
      walletInfo,
      electrumClient: electrumClient,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHd: hd,
      sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/1"),
      mwebHd: mwebHd,
      network: network,
    );
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  final bitcoin.HDWallet mwebHd;

  static Future<LitecoinWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      String? addressPageType,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      Map<String, int>? initialRegularAddressIndex,
      Map<String, int>? initialChangeAddressIndex}) async {
    return LitecoinWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      seedBytes: await mnemonicToSeedBytes(mnemonic),
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
  }) async {
    final snp =
        await ElectrumWalletSnapshot.load(name, walletInfo.type, password, LitecoinNetwork.mainnet);
    return LitecoinWallet(
      mnemonic: snp.mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp.addresses,
      initialBalance: snp.balance,
      seedBytes: await mnemonicToSeedBytes(snp.mnemonic),
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      addressPageType: snp.addressPageType,
    );
  }

  @action
  @override
  Future<void> startSync() async {
    await super.startSync();
    final stub = await CwMweb.stub();
    Timer.periodic(
      const Duration(milliseconds: 1500), (timer) async {
        final height = await electrumClient.getCurrentBlockChainTip() ?? 0;
        final resp = await stub.status(StatusRequest());
        if (resp.blockHeaderHeight < height) {
          int h = resp.blockHeaderHeight;
          syncStatus = SyncingSyncStatus(height - h, h / height);
        } else if (resp.mwebHeaderHeight < height) {
          int h = resp.mwebHeaderHeight;
          syncStatus = SyncingSyncStatus(height - h, h / height);
        } else if (resp.mwebUtxosHeight < height) {
          syncStatus = SyncingSyncStatus(1, 0.999);
        } else {
          syncStatus = SyncedSyncStatus();
        }
      });
    processMwebUtxos();
  }

  final Map<String, Utxo> mwebUtxos = {};

  Future<void> processMwebUtxos() async {
    final stub = await CwMweb.stub();
    final scanSecret = mwebHd.derive(0x80000000).privKey!;
    final req = UtxosRequest(scanSecret: hex.decode(scanSecret));
    await for (var utxo in stub.utxos(req)) {
      final mwebAddrs = (walletAddresses as LitecoinWalletAddresses).mwebAddrs;
      if (!mwebAddrs.contains(utxo.address)) continue;
      mwebUtxos[utxo.outputId] = utxo;

      final status = await stub.status(StatusRequest());
      var date = DateTime.now();
      var confirmations = 0;
      if (utxo.height > 0) {
        date = await electrumClient.getBlockTime(height: utxo.height);
        confirmations = status.blockHeaderHeight - utxo.height + 1;
      }
      final tx = ElectrumTransactionInfo(WalletType.litecoin,
        id: utxo.outputId, height: utxo.height,
        amount: utxo.value.toInt(), fee: 0,
        direction: TransactionDirection.incoming,
        isPending: utxo.height == 0,
        date: date, confirmations: confirmations,
        inputAddresses: [],
        outputAddresses: [utxo.address]);
      transactionHistory.addOne(tx);
      await transactionHistory.save();
    }
  }

  Future<void> checkMwebUtxosSpent() async {
    final List<String> outputIds = [];
    mwebUtxos.forEach((outputId, utxo) {
      if (utxo.height > 0)
        outputIds.add(outputId);
    });
    final stub = await CwMweb.stub();
    final resp = await stub.spent(SpentRequest(outputId: outputIds));
    final spent = resp.outputId;
    if (spent.isEmpty) return;
    final status = await stub.status(StatusRequest());
    final height = await electrumClient.getCurrentBlockChainTip();
    if (height == null || status.mwebUtxosHeight != height) return;
    final date = await electrumClient.getBlockTime(height: height);
    int amount = 0;
    Set<String> inputAddresses = {};
    var output = AccumulatorSink<Digest>();
    var input = sha256.startChunkedConversion(output);
    for (final outputId in spent) {
      input.add(hex.decode(outputId));
      amount += mwebUtxos[outputId]!.value.toInt();
      inputAddresses.add(mwebUtxos[outputId]!.address);
      mwebUtxos.remove(outputId);
    }
    input.close();
    var digest = output.events.single;
    final tx = ElectrumTransactionInfo(WalletType.litecoin,
      id: digest.toString(), height: height,
      amount: amount, fee: 0,
      direction: TransactionDirection.outgoing,
      isPending: false,
      date: date, confirmations: 1,
      inputAddresses: inputAddresses.toList(),
      outputAddresses: []);
    transactionHistory.addOne(tx);
    await transactionHistory.save();
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
}
