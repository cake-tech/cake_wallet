import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';

import 'package:hive/hive.dart';


import 'package:cw_evm/evm_chain_mnemonics.dart';
import 'package:cw_tron/tron_transaction_credentials.dart';
import 'package:cw_tron/tron_transaction_info.dart';
import 'package:cw_tron/tron_wallet_creation_credentials.dart';

import 'package:cw_tron/tron_client.dart';
import 'package:cw_tron/tron_token.dart';
import 'package:cw_tron/tron_wallet.dart';
import 'package:cw_tron/tron_wallet_service.dart';


part 'cw_tron.dart';

Tron? tron = CWTron();

abstract class Tron {
  List<String> getTronWordList(String language);
  WalletService createTronWalletService(Box<WalletInfo> walletInfoSource);
  WalletCredentials createTronNewWalletCredentials({required String name, WalletInfo? walletInfo});
  WalletCredentials createTronRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  WalletCredentials createTronRestoreWalletFromPrivateKey({required String name, required String privateKey, required String password});
  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);

  Object createTronTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
    int? feeRate,
  });

  Object createTronTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
    required int feeRate,
  });

  List<TronToken> getTronCurrencies(WalletBase wallet);
  Future<void> addTronToken(WalletBase wallet, CryptoCurrency token);
  Future<void> deleteTronToken(WalletBase wallet, CryptoCurrency token);
  Future<TronToken?> getTronToken(WalletBase wallet, String contractAddress);
  
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction);
  String getTokenAddress(CryptoCurrency asset);
}
  