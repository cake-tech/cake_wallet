import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

class CommonTestConstants {
  static final pin = [0, 8, 0, 1];
  static final String sendTestAmount = '0.00008';
  static final String exchangeTestAmount = '8';
  static final WalletType testWalletType = WalletType.solana;
  static final String testWalletName = 'Integrated Testing Wallet';
  static final CryptoCurrency testReceiveCurrency = CryptoCurrency.sol;
  static final CryptoCurrency testDepositCurrency = CryptoCurrency.usdtSol;
  static final String testWalletAddress = 'An2Y2fsUYKfYvN1zF89GAqR1e6GUMBg3qA83Y5ZWDf8L';
}
