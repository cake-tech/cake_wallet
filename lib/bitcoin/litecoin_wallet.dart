import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cake_wallet/bitcoin/bitcoin_mnemonic.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_priority.dart';
import 'package:cake_wallet/entities/transaction_priority.dart';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/wallet_info.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet_snapshot.dart';
import 'package:cake_wallet/bitcoin/electrum_wallet.dart';
import 'package:cake_wallet/bitcoin/bitcoin_address_record.dart';
import 'package:cake_wallet/bitcoin/electrum_balance.dart';
import 'package:cake_wallet/bitcoin/litecoin_network.dart';
import 'package:cake_wallet/bitcoin/utils.dart';

part 'litecoin_wallet.g.dart';

class LitecoinWallet = LitecoinWalletBase with _$LitecoinWallet;

abstract class LitecoinWalletBase extends ElectrumWallet with Store {
  LitecoinWalletBase(
      {@required String mnemonic,
      @required String password,
      @required WalletInfo walletInfo,
      List<BitcoinAddressRecord> initialAddresses,
      ElectrumBalance initialBalance,
      int accountIndex = 0})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            networkType: litecoinNetwork,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            accountIndex: accountIndex);

  static Future<LitecoinWallet> open({
    @required String name,
    @required WalletInfo walletInfo,
    @required String password,
  }) async {
    final snp = ElectrumWallletSnapshot(name, walletInfo.type, password);
    await snp.load();
    return LitecoinWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        accountIndex: snp.accountIndex);
  }

  @override
  String getAddress({@required int index, @required bitcoin.HDWallet hd}) =>
      generateP2WPKHAddress(hd: hd, index: index, networkType: networkType);

  @override
  Future<void> generateAddresses() async {
    if (addresses.length < 33) {
      final addressesCount = 22 - addresses.length;
      await generateNewAddresses(addressesCount,
          hd: hd, startIndex: addresses.length);

      final changeRoot = bitcoin.HDWallet.fromSeed(
              mnemonicToSeedBytes(mnemonic),
              network: networkType)
          .derivePath("m/0'/1");

      await generateNewAddresses(11,
          startIndex: 0, hd: changeRoot, isHidden: true);
    }
  }

  @override
  int feeRate(TransactionPriority priority) {
    if (priority is BitcoinTransactionPriority) {
      switch (priority) {
        case BitcoinTransactionPriority.slow:
          return 1;
        case BitcoinTransactionPriority.medium:
          return 2;
        case BitcoinTransactionPriority.fast:
          return 3;
      }
    }

    return 0;
  }
}
