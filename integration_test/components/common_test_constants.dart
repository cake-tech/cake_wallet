import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

class CommonTestConstants {
  static final pin = [0, 8, 0, 1];
  static final String sendTestAmount = '0.00008';
  static final String sendTestFiatAmount = '1.00';
  static final String exchangeTestAmount = '0.01';
  static final WalletType testWalletType = WalletType.solana;
  static final String testWalletName = 'Integrated Testing Wallet';
  static final CryptoCurrency sendTestReceiveCurrency = CryptoCurrency.sol;
  static final CryptoCurrency exchangeTestReceiveCurrency = CryptoCurrency.usdtSol;
  static final CryptoCurrency exchangeTestDepositCurrency = CryptoCurrency.sol;
  static final String testWalletAddress = '7TSTXnQZxQDA4JoNqs4DqVqE7oNWk2kmHkMT6DD6vw2S';
}
