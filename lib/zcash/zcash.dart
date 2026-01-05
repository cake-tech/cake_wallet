import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/monero_transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/address_info.dart';
import 'package:cw_core/receive_page_option.dart';


import 'package:cw_zcash/cw_zcash.dart';
import 'package:cw_zcash/src/zcash_wallet_addresses.dart';


part 'cw_zcash.dart';

Zcash? zcash = CWZcash();

abstract class Zcash {
  List<String> getZcashWordList(String language);
  WalletService createZcashWalletService(bool isDirect);
  WalletCredentials createZcashNewWalletCredentials(
      {required String name,
      WalletInfo? walletInfo,
      String? password,
      String? mnemonic,
      required String? passphrase});
  WalletCredentials createZcashRestoreWalletFromSeedCredentials(
      {required String name,
      required String mnemonic,
      required String password,
      String? passphrase});
  WalletCredentials createZcashRestoreWalletFromPrivateKey(
      {required String name, required String privateKey, required String password});
  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);
  Map<String, String> getKeys(Object wallet);

  Object createZcashTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
    int? feeRate,
  });

  Object createZcashTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
    required int feeRate,
  });

  int formatterZcashParseAmount(String amount);
  double formatterZcashAmountToDouble(
      {TransactionInfo? transaction, BigInt? amount, int exponent = 18});
  String formatterZcashAmountToString({required int amount});
  
  List<WalletInfoAddressInfo> getAddressInfos(Object wallet);
  
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getZcashTransactionPriorityAutomatic();
  TransactionPriority deserializeZcashTransactionPriority({required int raw});
  List<TransactionPriority> getTransactionPriorities();
  List<ReceivePageOption> getZcashReceivePageOptions(Object wallet);
  ReceivePageOption getSelectedAddressType(Object wallet);
  ZcashAddressType getZcashAddressType(ReceivePageOption option);
  Future<void> setAddressType(Object wallet, dynamic option);
  ZcashAddressType getOptionToType(ReceivePageOption option);
  void unlockDatabase(String password);
}

  