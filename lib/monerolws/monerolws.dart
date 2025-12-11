import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:mobx/mobx.dart';
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
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart' as ledger;
import 'package:polyseed/polyseed.dart';
import 'package:cw_core/account.dart' as monero_account;
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_monero/api/wallet_manager.dart';
import 'package:cw_monero/api/wallet.dart' as monero_wallet_api;
import 'package:cw_monero/ledger.dart';
import 'package:cw_monero/monero_unspent.dart';
import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/monero_wallet_service.dart';
import 'package:cw_monero/monero_wallet.dart';
import 'package:cw_monero/monero_transaction_info.dart';
import 'package:cw_monero/monero_transaction_creation_credentials.dart';
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
import 'package:cw_monero/pending_monero_transaction.dart';
// TODO: not finished yet
part 'cw_monero.dart';

Monero? monero = CWMonero();

class Account {
  Account({required this.id, required this.label, this.balance});
  final int id;
  final String label;
  final String? balance;
}

class Subaddress {
  Subaddress({required this.id, required this.label, required this.address, required this.received, required this.txCount});
  final int id;
  final String label;
  final String address;
  final String? received;
  final int txCount;
}

class MoneroBalance extends Balance {
  MoneroBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance = monero!.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance = monero!.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  MoneroBalance.fromString({required this.formattedFullBalance, required this.formattedUnlockedBalance})
      : fullBalance = monero!.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = monero!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(monero!.formatterMoneroParseAmount(amount: formattedUnlockedBalance), monero!.formatterMoneroParseAmount(amount: formattedFullBalance));

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
  late Account account;

  @observable
  late MoneroBalance balance;
}

abstract class Monero {
  MoneroAccountList getAccountList(Object wallet);

  MoneroSubaddressList getSubaddressList(Object wallet);

  TransactionHistoryBase getTransactionHistory(Object wallet);

  MoneroWalletDetails getMoneroWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  String getSubaddressLabel(Object wallet, int accountIndex, int addressIndex);

  int getHeightByDate({required DateTime date});
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getMoneroTransactionPrioritySlow();
  TransactionPriority getMoneroTransactionPriorityAutomatic();
  TransactionPriority deserializeMoneroTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);

  List<Unspent> getUnspents(Object wallet);
  Future<void> updateUnspents(Object wallet);

  Future<int> getCurrentHeight();

  Future<bool> commitTransactionUR(Object wallet, String ur);

  Map<String, String> exportOutputsUR(Object wallet);

  bool needExportOutputs(Object wallet, int amount);

  bool importKeyImagesUR(Object wallet, String ur);

  WalletCredentials createMoneroRestoreWalletFromKeysCredentials({required String name, required String spendKey, required String viewKey, required String address, required String password, required String language, required int height});
  WalletCredentials createMoneroRestoreWalletFromSeedCredentials({required String name, required String password, required String passphrase, required int height, required String mnemonic});
  WalletCredentials createMoneroRestoreWalletFromHardwareCredentials({required String name, required String password, required int height, required ledger.LedgerConnection ledgerConnection});
  WalletCredentials createMoneroNewWalletCredentials({required String name, required String language, required int seedType, required String? passphrase, String? password, String? mnemonic});
  Map<String, String> getKeys(Object wallet);
  int? getRestoreHeight(Object wallet);
  Object createMoneroTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority});
  Object createMoneroTransactionCreationCredentialsRaw({required List<OutputInfo> outputs, required TransactionPriority priority});
  String formatterMoneroAmountToString({required int amount});
  double formatterMoneroAmountToDouble({required int amount});
  int formatterMoneroParseAmount({required String amount});
  Account getCurrentAccount(Object wallet);
  void monerocCheck();
  bool isViewOnly();
  void setCurrentAccount(Object wallet, int id, String label, String? balance);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createMoneroWalletService(Box<UnspentCoinsInfo> unspentCoinSource);
  Map<String, String> pendingTransactionInfo(Object transaction);
  Future<void> setLedgerConnection(Object wallet, ledger.LedgerConnection connection);
  void resetLedgerConnection();
  void setGlobalLedgerConnection(ledger.LedgerConnection connection);
  String? getLastLedgerCommand();
  Map<String, List<int>> debugCallLength();
  Map<String, dynamic> getWalletCacheDebug();
}

abstract class MoneroSubaddressList {
  ObservableList<Subaddress> get subaddresses;
  void update(Object wallet, {required int accountIndex});
  void refresh(Object wallet, {required int accountIndex});
  List<Subaddress> getAll(Object wallet);
  Future<void> addSubaddress(Object wallet, {required int accountIndex, required String label});
  Future<void> setLabelSubaddress(Object wallet, {required int accountIndex, required int addressIndex, required String label});
}

abstract class MoneroAccountList {
  ObservableList<Account> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  List<Account> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}
