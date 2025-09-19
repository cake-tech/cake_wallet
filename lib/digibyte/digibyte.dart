import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';

import 'package:cw_digibyte/cw_digibyte.dart';

part 'cw_digibyte.dart';

Digibyte? digibyte = CWDigibyte();

abstract class Digibyte {
  WalletService createDigibyteWalletService(
    Box<WalletInfo> walletInfoSource,
    Box<UnspentCoinsInfo> unspentCoinSource,
    bool isDirect,
  );

  WalletCredentials createDigibyteNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  });

  WalletCredentials createDigibyteRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
  });

  WalletCredentials createDigibyteRestoreWalletFromWIFCredentials({
    required String name,
    required String password,
    required String wif,
    WalletInfo? walletInfo,
  });

  TransactionPriority deserializeDigibyteTransactionPriority(int raw);

  TransactionPriority getDefaultTransactionPriority();

  List<TransactionPriority> getTransactionPriorities();

  TransactionPriority getDigibyteTransactionPrioritySlow();
}
