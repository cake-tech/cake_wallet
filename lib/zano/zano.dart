import 'package:cw_zano/new_zano_wallet.dart';
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
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/get_height_by_date.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_zano/zano_transaction_info.dart';
import 'package:cw_zano/zano_transaction_history.dart';
import 'package:cw_core/account.dart' as monero_account;
import 'package:cw_zano/api/wallet.dart' as monero_wallet_api;
import 'package:cw_zano/mnemonics/english.dart';
import 'package:cw_zano/mnemonics/chinese_simplified.dart';
import 'package:cw_zano/mnemonics/dutch.dart';
import 'package:cw_zano/mnemonics/german.dart';
import 'package:cw_zano/mnemonics/japanese.dart';
import 'package:cw_zano/mnemonics/russian.dart';
import 'package:cw_zano/mnemonics/spanish.dart';
import 'package:cw_zano/mnemonics/portuguese.dart';
import 'package:cw_zano/mnemonics/french.dart';
import 'package:cw_zano/mnemonics/italian.dart';
import 'package:cw_zano/zano_transaction_creation_credentials.dart';
import 'package:cw_zano/api/balance_list.dart';

part 'cw_zano.dart';

Zano? zano = CWZano();

// class Account {
//   Account({required this.id, required this.label});
//   final int id;
//   final String label;
// }

// class Subaddress {
//   Subaddress({
//     required this.id,
//     required this.label,
//     required this.address});
//   final int id;
//   final String label;
//   final String address;
// }

class ZanoBalance extends Balance {
  ZanoBalance({required this.fullBalance, required this.unlockedBalance})
      : formattedFullBalance = zano!.formatterMoneroAmountToString(amount: fullBalance),
        formattedUnlockedBalance =
            zano!.formatterMoneroAmountToString(amount: unlockedBalance),
        super(unlockedBalance, fullBalance);

  ZanoBalance.fromString(
      {required this.formattedFullBalance,
      required this.formattedUnlockedBalance})
      : fullBalance = zano!.formatterMoneroParseAmount(amount: formattedFullBalance),
        unlockedBalance = zano!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
        super(zano!.formatterMoneroParseAmount(amount: formattedUnlockedBalance),
            zano!.formatterMoneroParseAmount(amount: formattedFullBalance));

  final int fullBalance;
  final int unlockedBalance;
  final String formattedFullBalance;
  final String formattedUnlockedBalance;

  @override
  String get formattedAvailableBalance => formattedUnlockedBalance;

  @override
  String get formattedAdditionalBalance => formattedFullBalance;
}

class AssetRate {
  AssetRate(this.asset, this.rate);

  final String asset;
  final int rate;
}

abstract class ZanoWalletDetails {
  // FIX-ME: it's abstruct class
  // @observable
  // late Account account;
  // FIX-ME: it's abstruct class
  @observable
  late ZanoBalance balance;
}

abstract class Zano {
  /**ZanoAccountList getAccountList(Object wallet);*/
  
  TransactionHistoryBase getTransactionHistory(Object wallet);

  ZanoWalletDetails getZanoWalletDetails(Object wallet);

  String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  int getHeightByDate({required DateTime date});
  Future<int> getCurrentHeight();
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeMoneroTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getMoneroWordList(String language);

  WalletCredentials createZanoRestoreWalletFromKeysCredentials({
      required String name,
      required String spendKey,
      required String viewKey,
      required String address,
      required String password,
      required String language,
      required int height});
  WalletCredentials createZanoRestoreWalletFromSeedCredentials({required String name, required String password, required int height, required String mnemonic});
  WalletCredentials createZanoNewWalletCredentials({required String name, String password});
  Map<String, String> getKeys(Object wallet);
  Object createZanoTransactionCreationCredentials({required List<Output> outputs, required TransactionPriority priority, required String assetType});
  String formatterMoneroAmountToString({required int amount});
  double formatterMoneroAmountToDouble({required int amount});
  int formatterMoneroParseAmount({required String amount});
  // Account getCurrentAccount(Object wallet);
  // void setCurrentAccount(Object wallet, int id, String label);
  void onStartup();
  int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createZanoWalletService(Box<WalletInfo> walletInfoSource);
  CryptoCurrency assetOfTransaction(TransactionInfo tx);
  List<AssetRate> getAssetRate();
}

// abstract class MoneroSubaddressList {
//   ObservableList<Subaddress> get subaddresses;
//   void update(Object wallet, {required int accountIndex});
//   void refresh(Object wallet, {required int accountIndex});
//   List<Subaddress> getAll(Object wallet);
//   Future<void> addSubaddress(Object wallet, {required int accountIndex, required String label});
//   Future<void> setLabelSubaddress(Object wallet,
//       {required int accountIndex, required int addressIndex, required String label});
// }

// abstract class ZanoAccountList {
//   ObservableList<Account> get accounts;
//   void update(Object wallet);
//   void refresh(Object wallet);
//   List<Account> getAll(Object wallet);
//   Future<void> addAccount(Object wallet, {required String label});
//   Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
// }
  