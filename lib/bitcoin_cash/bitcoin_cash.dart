
 import 'dart:typed_data';
 import 'package:cw_bitcoin_cash/src/bitcoin_cash_base.dart';
 import 'package:cw_core/transaction_priority.dart';
 import 'package:cw_core/unspent_coins_info.dart';
 import 'package:cw_core/wallet_credentials.dart';
 import 'package:cw_core/wallet_info.dart';
 import 'package:cw_core/wallet_service.dart';
 import 'package:hive/hive.dart';

part 'cw_bitcoin_cash.dart';

BitcoinCash? bitcoinCash = CWBitcoinCash();

  abstract class BitcoinCash {
  String getMnemonic(int? strength);
  Uint8List getSeedFromMnemonic(String seed);
  WalletService createBitcoinCashWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  WalletCredentials createBitcoinCashRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  // WalletCredentials createBitcoinCashRestoreWalletFromWIFCredentials({required String name, required String password, required String wif, WalletInfo? walletInfo});
  WalletCredentials createBitcoinCashNewWalletCredentials({required String name, WalletInfo? walletInfo});


  //
  // WalletCredentials createBitcoinRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  // WalletCredentials createBitcoinRestoreWalletFromWIFCredentials({required String name, required String password, required String wif, WalletInfo? walletInfo});

  //
  // Map<String, String> getWalletKeys(Object wallet);
  // List<TransactionPriority> getTransactionPriorities();
  // List<TransactionPriority> getLitecoinTransactionPriorities();
  TransactionPriority deserializeBitcoinCashTransactionPriority(int raw);
  // TransactionPriority deserializeLitecoinTransactionPriority(int raw);
  // int getFeeRate(Object wallet, TransactionPriority priority);
  // Future<void> generateNewAddress(Object wallet);
  // Object createBitcoinTransactionCredentials(List<Output> outputs, {required TransactionPriority priority, int? feeRate});
  // Object createBitcoinTransactionCredentialsRaw(List<OutputInfo> outputs, {TransactionPriority? priority, required int feeRate});
  //
  // List<String> getAddresses(Object wallet);
  // String getAddress(Object wallet);
  //
  // String formatterBitcoinAmountToString({required int amount});
  // double formatterBitcoinAmountToDouble({required int amount});
  // int formatterStringDoubleToBitcoinAmount(String amount);
  // String bitcoinTransactionPriorityWithLabel(TransactionPriority priority, int rate);
  //
  // void updateUnspents(Object wallet);

  // WalletService createLitecoinWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource);
  TransactionPriority getDefaultTransactionPriority() => throw UnimplementedError('getDefaultTransactionPriority');
  // TransactionPriority getBitcoinTransactionPriorityMedium();
  // TransactionPriority getLitecoinTransactionPriorityMedium();
  // TransactionPriority getBitcoinTransactionPrioritySlow();
  // TransactionPriority getLitecoinTransactionPrioritySlow();
  }
