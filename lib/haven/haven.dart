import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/output_info.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:hive/hive.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_haven/haven_wallet_service.dart';
import 'package:cw_haven/haven_wallet.dart';
import 'package:cw_haven/haven_transaction_info.dart';
import 'package:cw_haven/haven_transaction_history.dart';
import 'package:cw_core/account.dart' as monero_account;
import 'package:cw_haven/api/wallet.dart' as monero_wallet_api;
import 'package:cw_haven/mnemonics/english.dart';
import 'package:cw_haven/mnemonics/chinese_simplified.dart';
import 'package:cw_haven/mnemonics/dutch.dart';
import 'package:cw_haven/mnemonics/german.dart';
import 'package:cw_haven/mnemonics/japanese.dart';
import 'package:cw_haven/mnemonics/russian.dart';
import 'package:cw_haven/mnemonics/spanish.dart';
import 'package:cw_haven/mnemonics/portuguese.dart';
import 'package:cw_haven/mnemonics/french.dart';
import 'package:cw_haven/mnemonics/italian.dart';
import 'package:cw_haven/haven_transaction_creation_credentials.dart';

part 'cw_haven.dart';

Haven haven = CWHaven();

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

class HavenBalance extends Balance {
  HavenBalance({@required this.fullBalance, @required this.unlockedBalance})
      : formattedFullBalance = haven.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            haven.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  HavenBalance.fromString(
      {@required this.formattedFullBalance,
      @required this.formattedUnlockedBalance})
      : fullBalance = haven.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = haven.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(haven.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
            haven.formatterMoneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

abstract class HavenWalletDetails {
  @observable
  Account account;

  @observable
  HavenBalance balance;
}

abstract class Haven {
  HavenAccountList getAccountList(Object wallet);
  
  MoneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  HavenWalletDetails getMoneroWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  int getHeigthByDate({DateTime date});
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeMoneroTransactionPriority({int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);

  WalletCredentials createHavenRestoreWalletFromKeysCredentials({
      String name,
            String spendKey,
            String viewKey,
            String address,
            String password,
            String language,
            int height});
  WalletCredentials createHavenRestoreWalletFromSeedCredentials({String name, String password, int height, String mnemonic});
  WalletCredentials createHavenNewWalletCredentials({String name, String password, String language});
  Map<String, String> getKeys(Object wallet);
  Object createHavenTransactionCreationCredentials({List<Output> outputs, TransactionPriority priority, String assetType});
  String formatterMoneroAmountToString({int amount});
  double formatterMoneroAmountToDouble({int amount});
  int formatterMoneroParseAmount({String amount});
  Account getCurrentAccount(Object wallet);
  void setCurrentAccount(Object wallet, int id, String label);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createHavenWalletService(Box<WalletInfo> walletInfoSource);
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

abstract class HavenAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {String label});
  Future<void> setLabelAccount(Object wallet, {int accountIndex, String label});
}
  