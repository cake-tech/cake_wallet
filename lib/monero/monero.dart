import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/output_info.dart';
import 'package:flutter_libmonero/view_model/send/output.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:cw_monero/monero_transaction_info.dart';
import 'package:cw_monero/monero_transaction_history.dart';
import 'package:cw_monero/monero_transaction_creation_credentials.dart';
import 'package:cw_core/account.dart' as monero_account;
import 'package:cw_monero/api/wallet.dart' as monero_wallet_api;
import 'package:cw_monero/mnemonics/english.dart';
import 'package:cw_monero/mnemonics/chinese_simplified.dart';
import 'package:cw_monero/mnemonics/dutch.dart';
import 'package:cw_monero/mnemonics/german.dart';
import 'package:cw_monero/mnemonics/japanese.dart';
import 'package:cw_monero/mnemonics/russian.dart';
import 'package:cw_monero/mnemonics/spanish.dart';
import 'package:cw_monero/mnemonics/portuguese.dart';
import 'package:cw_monero/mnemonics/french.dart';
import 'package:cw_monero/mnemonics/italian.dart';

part 'cw_monero.dart';

Monero monero = CWMonero();

class Account {
  Account({this.id, this.label});
  final int id;
  final String label;
}

class Subaddress {
  Subaddress({this.id, this.accountId, this.label, this.address});
  final int id;
  final int accountId;
  final String label;
  final String address;
}

class MoneroBalance extends Balance {
  MoneroBalance({@required this.fullBalance, @required this.unlockedBalance})
      : formattedFullBalance =
            monero.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            monero.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  MoneroBalance.fromString(
      {@required this.formattedFullBalance,
      @required this.formattedUnlockedBalance})
      : fullBalance =
            monero.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance =
            monero.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(
            monero.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
            monero.formatterMoneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

abstract class MoneroWalletDetails {
  @observable
  Account account;

  @observable
  MoneroBalance balance;
}

abstract class Monero {
  MoneroAccountList getAccountList(Object wallet);

  MoneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  MoneroWalletDetails getMoneroWalletDetails(Object wallet);

  String getTransactionAddress(
      Object wallet, int accountIndex, int addressIndex);

  int getHeigthByDate({DateTime date});
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeMoneroTransactionPriority({int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);

  WalletCredentials createMoneroRestoreWalletFromKeysCredentials(
      {String name,
      String spendKey,
      String viewKey,
      String address,
      String password,
      String language,
      int height});
  WalletCredentials createMoneroRestoreWalletFromSeedCredentials(
      {String name, String password, int height, String mnemonic});
  WalletCredentials createMoneroNewWalletCredentials(
      {String name, String password, String language});
  Map<String, String> getKeys(Object wallet);
  Object createMoneroTransactionCreationCredentials(
      {List<Output> outputs, TransactionPriority priority});
  String formatterMoneroAmountToString({int amount});
  double formatterMoneroAmountToDouble({int amount});
  int formatterMoneroParseAmount({String amount});
  Account getCurrentAccount(Object wallet);
  void setCurrentAccount(Object wallet, int id, String label);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createMoneroWalletService(Box<WalletInfo> walletInfoSource);
}

abstract class MoneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {int accountIndex});
  void refresh(Object wallet, {int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {int accountIndex, String label});
  Future<void> setLabelSubaddress(Object wallet,
      {int accountIndex, int addressIndex, String label});
}

abstract class MoneroAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {String label});
  Future<void> setLabelAccount(Object wallet, {int accountIndex, String label});
}
