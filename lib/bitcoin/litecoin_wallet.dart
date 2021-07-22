import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/bitcoin/unspent_coins_info.dart';
import 'package:cake_wallet/bitcoin/litecoin_wallet_addresses.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet_snapshot.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/electrum_balance.dart';
import 'package:cake_wallet/bitcoin/litecoin_network.dart';

part 'litecoin_wallet.g.dart';

class LitecoinWallet = LitecoinWalletBase with _$LitecoinWallet;

abstract class LitecoinWalletBase extends ElectrumWallet with Store {
  LitecoinWalletBase(
      {@required String mnemonic,
      @required String password,
      @required WalletInfo walletInfo,
      @required Box<UnspentCoinsInfo> unspentCoinsInfo,
      List<BitcoinAddressRecord> initialAddresses,
      ElectrumBalance initialBalance,
      int accountIndex = 0})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: litecoinNetwork,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance) {
    walletAddresses = LitecoinWalletAddresses(
        walletInfo,
        initialAddresses: initialAddresses,
        accountIndex: accountIndex,
        hd: hd,
        networkType: networkType,
        mnemonic: mnemonic);
  }

  static Future<LitecoinWallet> open({
    @required String name,
    @required WalletInfo walletInfo,
    @required Box<UnspentCoinsInfo> unspentCoinsInfo,
    @required String password,
  }) async {
    final snp = ElectrumWallletSnapshot(name, walletInfo.type, password);
    await snp.load();
    return LitecoinWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        accountIndex: snp.accountIndex);
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
