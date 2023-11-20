import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/nano_account_info_response.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/view_model/send/output.dart';

import 'package:cw_nano/nano_client.dart';
import 'package:cw_nano/nano_mnemonic.dart';
import 'package:cw_nano/nano_wallet.dart';
import 'package:cw_nano/nano_wallet_service.dart';
import 'package:cw_nano/nano_transaction_info.dart';
import 'package:cw_nano/nano_transaction_credentials.dart';
import 'package:cw_nano/nano_wallet_creation_credentials.dart';
// needed for nano_util:
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import "package:ed25519_hd_key/ed25519_hd_key.dart";
import 'package:libcrypto/libcrypto.dart';
import 'package:nanodart/nanodart.dart' as ND;
import 'package:decimal/decimal.dart';

part 'cw_nano.dart';

Nano? nano = CWNano();
NanoUtil? nanoUtil = CWNanoUtil();

abstract class Nano {
  NanoAccountList getAccountList(Object wallet);

  Account getCurrentAccount(Object wallet);

  void setCurrentAccount(Object wallet, int id, String label, String? balance);

  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource);

  WalletCredentials createNanoNewWalletCredentials({
    required String name,
    String password,
  });
  
  WalletCredentials createNanoRestoreWalletFromSeedCredentials({
    required String name,
    required String password,
    required String mnemonic,
    DerivationType? derivationType,
  });

  WalletCredentials createNanoRestoreWalletFromKeysCredentials({
    required String name,
    required String password,
    required String seedKey,
    DerivationType? derivationType,
  });

  List<String> getNanoWordList(String language);
  Map<String, String> getKeys(Object wallet);
  Object createNanoTransactionCredentials(List<Output> outputs);
  Future<void> changeRep(Object wallet, String address);
  Future<void> updateTransactions(Object wallet);
  BigInt getTransactionAmountRaw(TransactionInfo transactionInfo);
  String getRepresentative(Object wallet);
}

abstract class NanoAccountList {
  ObservableList<NanoAccount> get accounts;
  void update(Object wallet);
  void refresh(Object wallet);
  Future<List<NanoAccount>> getAll(Object wallet);
  Future<void> addAccount(Object wallet, {required String label});
  Future<void> setLabelAccount(Object wallet, {required int accountIndex, required String label});
}

abstract class NanoUtil {
  String seedToPrivate(String seed, int index);
  String seedToAddress(String seed, int index);
  String seedToMnemonic(String seed);
  Future<String> mnemonicToSeed(String mnemonic);
  String privateKeyToPublic(String privateKey);
  String addressToPublicKey(String publicAddress);
  String privateKeyToAddress(String privateKey);
  String publicKeyToAddress(String publicKey);
  bool isValidSeed(String seed);
  Future<String> hdMnemonicListToSeed(List<String> words);
  Future<String> hdSeedToPrivate(String seed, int index);
  Future<String> hdSeedToAddress(String seed, int index);
  Future<String> uniSeedToAddress(String seed, int index, String type);
  Future<String> uniSeedToPrivate(String seed, int index, String type);
  bool isValidBip39Seed(String seed);
  static const int maxDecimalDigits = 6; // Max digits after decimal
  BigInt rawPerNano = BigInt.parse("1000000000000000000000000000000");
  BigInt rawPerNyano = BigInt.parse("1000000000000000000000000");
  BigInt rawPerBanano = BigInt.parse("100000000000000000000000000000");
  BigInt rawPerXMR = BigInt.parse("1000000000000");
  BigInt convertXMRtoNano = BigInt.parse("1000000000000000000");
  String getRawAsDecimalString(String? raw, BigInt? rawPerCur);
  String getRawAsUsableString(String? raw, BigInt rawPerCur);
  String getRawAccuracy(String? raw, BigInt rawPerCur);
  String getAmountAsRaw(String amount, BigInt rawPerCur);

  // derivationInfo:
  Future<AccountInfoResponse?> getInfoFromSeedOrMnemonic(
    DerivationType derivationType, {
    String? seedKey,
    String? mnemonic,
    required Node node,
  });
  Future<List<DerivationType>> compareDerivationMethods({
    String? mnemonic,
    String? privateKey,
    required Node node,
  });
}
  