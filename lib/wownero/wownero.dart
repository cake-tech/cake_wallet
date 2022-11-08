import 'package:cw_core/account.dart' as wownero_account;
import 'package:cw_core/balance.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_wownero/api/wallet.dart' as wownero_wallet_api;
//import 'package:cw_wownero/mnemonics/english.dart';
import 'package:cw_wownero/mnemonics/english14.dart';
import 'package:cw_wownero/mnemonics/english25.dart';
import 'package:cw_wownero/wownero_amount_format.dart';
import 'package:cw_wownero/wownero_transaction_creation_credentials.dart';
import 'package:cw_wownero/wownero_transaction_info.dart';
import 'package:cw_wownero/wownero_wallet.dart';
import 'package:cw_wownero/wownero_wallet_service.dart';
import 'package:flutter_libmonero/view_model/send/output.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'cw_wownero.dart';

Wownero wownero = CWWownero();

class Account {
  Account({this.id, this.label});
  final int? id;
  final String? label;
}

class Subaddress {
  Subaddress({this.id, this.accountId, this.label, this.address});
  final int? id;
  final int? accountId;
  final String? label;
  final String? address;
}

class WowneroBalance extends Balance {
  WowneroBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance =
            wownero.formatterWowneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            wownero.formatterWowneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  WowneroBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance})
      : fullBalance =
            wownero.formatterWowneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = wownero.formatterWowneroParseAmount(
            amount: formattedUnlockedBalance),
        super(
            wownero.formatterWowneroParseAmount(
                amount: formattedUnlockedBalance),
            wownero.formatterWowneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

abstract class WowneroWalletDetails {
  @observable
  Account? account;

  @observable
  WowneroBalance? balance;
}

abstract class Wownero {
  WowneroAccountList getAccountList(Object wallet);

  WowneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase? getTransactionHistory(Object wallet);

  WowneroWalletDetails getWowneroWalletDetails(Object wallet);

  String getTransactionAddress(
      Object wallet, int accountIndex, int addressIndex);

  String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex);

  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority? deserializeMoneroTransactionPriority({int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getWowneroWordList(String language);

  WalletCredentials createWowneroRestoreWalletFromKeysCredentials(
      {String name,
      String spendKey,
      String viewKey,
      String address,
      String password,
      String language,
      int height});
  WalletCredentials createWowneroRestoreWalletFromSeedCredentials(
      {String name, String password, int height, String mnemonic});
  WalletCredentials createWowneroNewWalletCredentials(
      {String name, String password, String language, int seedWordsLength = 14});
  Map<String, String?> getKeys(Object wallet);
  Object createWowneroTransactionCreationCredentials(
      {List<Output> outputs, TransactionPriority priority});
  String formatterWowneroAmountToString({int? amount});
  double formatterWowneroAmountToDouble({int? amount});
  int formatterWowneroParseAmount({String? amount});
  Account getCurrentAccount(Object wallet);
  void setCurrentAccount(Object wallet, int id, String label);
  void onStartup();
  int? getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createWowneroWalletService(Box<WalletInfo> walletInfoSource);
}

abstract class WowneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {int accountIndex});
  void refresh(Object wallet, {int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {int accountIndex, String label});
  Future<void> setLabelSubaddress(Object wallet,
      {int accountIndex, int addressIndex, String label});
}

abstract class WowneroAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {String label});
  Future<void> setLabelAccount(Object wallet, {int accountIndex, String label});
}
