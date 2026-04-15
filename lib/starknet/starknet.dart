import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/starknet_token.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';

import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_wallet.dart';
import 'package:cw_starknet/starknet_mnemonics.dart';
import 'package:cw_starknet/starknet_wallet_service.dart';
import 'package:cw_starknet/starknet_transaction_info.dart';
import 'package:cw_starknet/starknet_transaction_credentials.dart';
import 'package:cw_starknet/starknet_wallet_creation_credentials.dart';

part 'cw_starknet.dart';

Starknet? starknet = CWStarknet();

abstract class Starknet {
  List<String> getStarknetWordList(String language);
  WalletService createStarknetWalletService(bool isDirect);
  WalletCredentials createStarknetNewWalletCredentials(
      {required String name,
      WalletInfo? walletInfo,
      String? password,
      String? mnemonic,
      String? passphrase});
  WalletCredentials createStarknetRestoreWalletFromSeedCredentials(
      {required String name,
      required String mnemonic,
      required String password,
      String? passphrase});
  WalletCredentials createStarknetRestoreWalletFromPrivateKey(
      {required String name,
      required String privateKey,
      required String password});
  WalletCredentials createStarknetRestoreWalletFromPublicKey(
      {required String name,
      required String publicKey,
      required String password,
      String? accountClassHashHex});

  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);

  Object createStarknetTransactionCredentials(
    List<Output> outputs, {
    required CryptoCurrency currency,
  });

  Object createStarknetTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    required CryptoCurrency currency,
  });

  List<StarknetToken> getStarknetTokenCurrencies(WalletBase wallet);
  Future<void> addStarknetToken(
    WalletBase wallet,
    CryptoCurrency token,
    String contractAddress,
  );
  Future<void> deleteStarknetToken(WalletBase wallet, CryptoCurrency token);
  Future<CryptoCurrency?> getStarknetToken(
      WalletBase wallet, String contractAddress);
  String getTokenAddress(CryptoCurrency asset);

  double getTransactionAmountRaw(TransactionInfo transactionInfo);
  CryptoCurrency assetOfTransaction(
      WalletBase wallet, TransactionInfo transaction);
  double? getEstimateFees(WalletBase wallet, {CryptoCurrency? currency});

  Future<List<String>> signTypedData(
    WalletBase wallet,
    String typedDataJson, {
    String? address,
  });

  Future<String> executeWalletConnectCalls(
    WalletBase wallet,
    List<StarknetExecutionCall> calls,
  );

  Future<bool> commitTransactionUR(WalletBase wallet, String ur);

  bool supportsOfflineUrSigning(WalletBase wallet);

  bool isValidAddress(String address);
}
