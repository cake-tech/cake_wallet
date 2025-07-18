import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';

import 'package:cw_dogecoin/cw_dogecoin.dart';

part 'cw_dogecoin.dart';

DogeCoin? dogecoin = CWDogeCoin();

abstract class DogeCoin {

  WalletService createDogeCoinWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect);

  WalletCredentials createDogeCoinNewWalletCredentials(
      {required String name, WalletInfo? walletInfo, String? password, String? passphrase, String? mnemonic});

  WalletCredentials createDogeCoinRestoreWalletFromSeedCredentials(
      {required String name, required String mnemonic, required String password, String? passphrase});

  TransactionPriority deserializeDogeCoinTransactionPriority(int raw);

  TransactionPriority getDefaultTransactionPriority();

  List<TransactionPriority> getTransactionPriorities();

  TransactionPriority getDogeCoinTransactionPrioritySlow();
}
