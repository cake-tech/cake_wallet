import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';

CryptoCurrency getCryptoCurrency(WalletType walletType) {
  switch (walletType) {
    case WalletType.monero:
      return CryptoCurrency.xmr;
    case WalletType.bitcoin:
      return CryptoCurrency.btc;
    default:
      return CryptoCurrency.xmr;
  }
}