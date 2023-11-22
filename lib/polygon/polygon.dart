import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_ethereum/ethereum_mnemonics.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:hive/hive.dart';
import 'package:web3dart/web3dart.dart';

import 'package:cw_polygon/polygon_formatter.dart';
import 'package:cw_polygon/polygon_transaction_credentials.dart';
import 'package:cw_polygon/polygon_transaction_info.dart';
import 'package:cw_polygon/polygon_wallet.dart';
import 'package:cw_polygon/polygon_wallet_creation_credentials.dart';
import 'package:cw_polygon/polygon_wallet_service.dart';
import 'package:cw_polygon/polygon_transaction_priority.dart';

part 'cw_polygon.dart';

Polygon? polygon = CWPolygon();

abstract class Polygon {
  List<String> getPolygonWordList(String language);
  WalletService createPolygonWalletService(Box<WalletInfo> walletInfoSource);
  WalletCredentials createPolygonNewWalletCredentials(
      {required String name, WalletInfo? walletInfo});
  WalletCredentials createPolygonRestoreWalletFromSeedCredentials(
      {required String name,
      required String mnemonic,
      required String password});
  WalletCredentials createPolygonRestoreWalletFromPrivateKey(
      {required String name,
      required String privateKey,
      required String password});
  String getAddress(WalletBase wallet);
  String getPrivateKey(WalletBase wallet);
  String getPublicKey(WalletBase wallet);
  TransactionPriority getDefaultTransactionPriority();
  TransactionPriority getPolygonTransactionPrioritySlow();
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority deserializePolygonTransactionPriority(int raw);

  Object createPolygonTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  });

  Object createPolygonTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  });

  int formatterPolygonParseAmount(String amount);
  double formatterPolygonAmountToDouble(
      {TransactionInfo? transaction, BigInt? amount, int exponent = 18});
  List<Erc20Token> getERC20Currencies(WalletBase wallet);
  Future<void> addErc20Token(WalletBase wallet, Erc20Token token);
  Future<void> deleteErc20Token(WalletBase wallet, Erc20Token token);
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress);

  CryptoCurrency assetOfTransaction(
      WalletBase wallet, TransactionInfo transaction);
  void updateEtherscanUsageState(WalletBase wallet, bool isEnabled);
  Web3Client? getWeb3Client(WalletBase wallet);
}
