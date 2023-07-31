import 'package:cw_core/crypto_currency.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_info.dart';
import 'package:cw_nano/nano_wallet_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:cw_nano/nano_balance.dart';
import 'package:cw_nano/nano_wallet_creation_credentials.dart';
import 'package:cw_nano/nano_transaction_credentials.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:cw_nano/nano_mnemonic.dart';

part 'cw_nano.dart';

Nano? nano = CWNano();

class Account {
  Account({required this.id, required this.label, this.balance});
  final int id;
  final String label;
  final String? balance;
}

abstract class NanoWalletDetails {
  @observable
  late Account account;

  @observable
  late NanoBalance balance;
}

abstract class Nano {
  // NanoAccountList getAccountList(Object wallet);

  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  NanoWalletDetails getNanoWalletDetails(Object wallet);

  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String password,
  });

  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    DerivationType? derivationType,
  });

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  void onStartup();

  List<String> getNanoWordList(String language);

  Map<String, String> getKeys(Object wallet);
  Object createNanoTransactionCredentials(List<Output> outputs);
}

abstract class NanoAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}
