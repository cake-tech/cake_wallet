import 'package:cake_wallet/utils/language_list.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_zano/mnemonics/english.dart';
import 'package:cw_zano/model/zano_asset.dart';
import 'package:cw_zano/model/zano_transaction_credentials.dart';
import 'package:cw_zano/model/zano_transaction_info.dart';
import 'package:cw_zano/zano_formatter.dart';
import 'package:cw_zano/zano_wallet.dart';
import 'package:cw_zano/zano_wallet_service.dart';
import 'package:hive/hive.dart';

part 'cw_zano.dart';

Zano? zano = CWZano();

abstract class Zano {
  //TransactionHistoryBase getTransactionHistory(Object wallet);
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
  //Map<String, String> getKeys(Object wallet);
  Object createZanoTransactionCredentials({required List<Output> outputs, required TransactionPriority priority, required CryptoCurrency currency});
  double formatterIntAmountToDouble({required int amount, required CryptoCurrency currency});
  int formatterParseAmount({required String amount, required CryptoCurrency currency});
  //int getTransactionInfoAccountId(TransactionInfo tx);
  WalletService createZanoWalletService(Box<WalletInfo> walletInfoSource);
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo tx);
  List<ZanoAsset> getZanoAssets(WalletBase wallet);
  String getZanoAssetAddress(CryptoCurrency asset);
  Future<void> changeZanoAssetAvailability(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency> addZanoAssetById(WalletBase wallet, String assetId);
  Future<void> deleteZanoAsset(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency?> getZanoAsset(WalletBase wallet, String contractAddress);
  String getAddress(WalletBase wallet);
}
