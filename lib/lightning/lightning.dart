import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:intl/intl.dart';



Lightning? lightning;

abstract class Lightning {
  String formatterLightningAmountToString({required int amount});
  double formatterLightningAmountToDouble({required int amount});
  int formatterStringDoubleToLightningAmount(String amount);
  WalletService createLightningWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  List<ReceivePageOption> getLightningReceivePageOptions();
  String satsToLightningString(int sats);
  ReceivePageOption getOptionInvoice();
  ReceivePageOption getOptionOnchain();
  String bitcoinAmountToLightningString({required int amount});
  int bitcoinAmountToLightningAmount({required int amount});
  double bitcoinDoubleToLightningDouble({required double amount});
  double lightningDoubleToBitcoinDouble({required double amount});
  Map<String, int> getIncomingPayments(Object wallet);
  void clearIncomingPayments(Object wallet);
  String lightningTransactionPriorityWithLabel(TransactionPriority priority, int rate, {int? customRate});
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority getLightningTransactionPriorityCustom();
  int getFeeRate(Object wallet, TransactionPriority priority);
  int getMaxCustomFeeRate(Object wallet);
  Future<void> fetchFees(Object wallet);
  Future<int> calculateEstimatedFeeAsync(Object wallet, TransactionPriority? priority, int? amount);
  Future<int> getEstimatedFeeWithFeeRate(Object wallet, int feeRate, int? amount);
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority deserializeLightningTransactionPriority({required int raw});
  String getBreezApiKey();
}
  