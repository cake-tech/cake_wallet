import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_wallet_creation_credentials.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_lightning/lightning_wallet_service.dart';

part 'cw_lightning.dart';

Lightning? lightning = CWLightning();

class ElectrumSubAddress {
  ElectrumSubAddress(
      {required this.id,
      required this.name,
      required this.address,
      required this.txCount,
      required this.balance,
      required this.isChange});
  final int id;
  final String name;
  final String address;
  final int txCount;
  final int balance;
  final bool isChange;
}

abstract class Lightning {
  TransactionPriority getMediumTransactionPriority();

  WalletCredentials createLightningRestoreWalletFromSeedCredentials(
      {required String name, required String mnemonic, required String password});
  WalletCredentials createLightningRestoreWalletFromWIFCredentials(
      {required String name,
      required String password,
      required String wif,
      WalletInfo? walletInfo});
  WalletCredentials createLightningNewWalletCredentials(
      {required String name, WalletInfo? walletInfo});
  List<String> getWordList();
  Map<String, String> getWalletKeys(Object wallet);
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority deserializeLightningTransactionPriority(int raw);
  int getFeeRate(Object wallet, TransactionPriority priority);
  Future<void> generateNewAddress(Object wallet, String label);
  Future<void> updateAddress(Object wallet, String address, String label);
  Object createLightningTransactionCredentials(List<Output> outputs,
      {required TransactionPriority priority, int? feeRate});
  Object createLightningTransactionCredentialsRaw(List<OutputInfo> outputs,
      {TransactionPriority? priority, required int feeRate});

  List<String> getAddresses(Object wallet);
  String getAddress(Object wallet);

  List<ElectrumSubAddress> getSubAddresses(Object wallet);

  String formatterLightningAmountToString({required int amount});
  double formatterLightningAmountToDouble({required int amount});
  int formatterStringDoubleToLightningAmount(String amount);
  String lightningTransactionPriorityWithLabel(TransactionPriority priority, int rate);

  List<Unspent> getUnspents(Object wallet);
  Future<void> updateUnspents(Object wallet);
  WalletService createLightningWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  TransactionPriority getLightningTransactionPriorityMedium();
  TransactionPriority getLightningTransactionPrioritySlow();
}
