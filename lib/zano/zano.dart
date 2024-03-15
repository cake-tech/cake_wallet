import 'package:cake_wallet/utils/language_list.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_zano/zano_asset.dart';
import 'package:cw_zano/zano_transaction_credentials.dart';
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
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_zano/zano_transaction_info.dart';
import 'package:cw_zano/mnemonics/english.dart';

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

  // String getTransactionAddress(Object wallet, int accountIndex, int addressIndex);

  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeMoneroTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<String> getWordList(String language);

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
  List<ZanoAsset> getZanoAssets(WalletBase wallet);
  String getZanoAssetAddress(CryptoCurrency asset);
  Future<void> addZanoAsset(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency> addZanoAssetById(WalletBase wallet, String assetId);
  Future<void> deleteZanoAsset(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency?> getZanoAsset(WalletBase wallet, String contractAddress);
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
  
