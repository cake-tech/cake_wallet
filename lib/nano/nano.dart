
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cw_ethereum/ethereum_formatter.dart';
import 'package:cw_ethereum/ethereum_mnemonics.dart';
import 'package:cw_ethereum/ethereum_transaction_credentials.dart';
import 'package:cw_ethereum/ethereum_transaction_info.dart';
import 'package:cw_ethereum/ethereum_wallet.dart';
import 'package:cw_ethereum/ethereum_wallet_creation_credentials.dart';
import 'package:cw_ethereum/ethereum_wallet_service.dart';
import 'package:cw_ethereum/ethereum_transaction_priority.dart';
import 'package:hive/hive.dart';

part 'cw_nano.dart';

Nano? nano = CWNano();

abstract class Nano {
  List<String> getNanoWordList(String language);
  WalletService createNanoWalletService(Box<WalletInfo> walletInfoSource);
  WalletCredentials createEthereumNewWalletCredentials({required String name, WalletInfo? walletInfo});
  WalletCredentials createEthereumRestoreWalletFromSeedCredentials({required String name, required String mnemonic, required String password});
  String getAddress(WalletBase wallet);
  TransactionPriority getDefaultTransactionPriority();
  List<TransactionPriority> getTransactionPriorities();
  TransactionPriority deserializeEthereumTransactionPriority(int raw);
  int getEstimatedFee(Object wallet, TransactionPriority priority);

  Object createEthereumTransactionCredentials(
    List<Output> outputs, {
    required TransactionPriority priority,
    required CryptoCurrency currency,
    int? feeRate,
  });

  Object createEthereumTransactionCredentialsRaw(
    List<OutputInfo> outputs, {
    TransactionPriority? priority,
    required CryptoCurrency currency,
    required int feeRate,
  });

  int formatterEthereumParseAmount(String amount);
  double formatterEthereumAmountToDouble({required TransactionInfo transaction});
  List<Erc20Token> getERC20Currencies(WalletBase wallet);
  Future<void> addErc20Token(WalletBase wallet, Erc20Token token);
  Future<void> deleteErc20Token(WalletBase wallet, Erc20Token token);
  Future<Erc20Token?> getErc20Token(WalletBase wallet, String contractAddress);
  
  CryptoCurrency assetOfTransaction(WalletBase wallet, TransactionInfo transaction);
}
  