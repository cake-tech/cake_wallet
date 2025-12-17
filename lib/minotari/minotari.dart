import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';


import 'package:cw_minotari/minotari_wallet.dart';
import 'package:cw_minotari/minotari_wallet_service.dart';
import 'package:cw_minotari/minotari_transaction_priority.dart';
import 'package:cw_minotari/pending_minotari_transaction.dart';

part 'cw_minotari.dart';

Minotari? minotari = CWMinotari();

abstract class Minotari {
  List<String> getMinotariWordList(String language);

  WalletService createMinotariWalletService(
    Box<UnspentCoinsInfo> unspentCoinsInfoSource,
  );

  WalletCredentials createMinotariNewWalletCredentials({
    required String name,
    String? mnemonic,
    WalletInfo? walletInfo,
  });

  WalletCredentials createMinotariRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required int height,
  });

  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getMinotariTransactionPrioritySlow();
  TransactionPriority getMinotariTransactionPriorityMedium();
  TransactionPriority getMinotariTransactionPriorityFast();
  List<TransactionPriority> getTransactionPriorities();

  String getAddress(WalletBase wallet);
  String? getSeed(WalletBase wallet);

  Object createMinotariTransactionCredentials(List<Output> outputs);

  int getHeightByDate({required DateTime date});
  Future<int> getCurrentHeight();
  TransactionHistoryBase getTransactionHistory(Object wallet);

  Future<MinotariWallet> createMinotariWallet(WalletInfo walletInfo);

  String getAssetShortName(CryptoCurrency asset);
  String getAssetFullName(CryptoCurrency asset);
}

  