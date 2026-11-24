import "package:cw_core/crypto_currency.dart";
import "package:cw_core/external_currency.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";

WalletType? depositWalletType(CryptoCurrency currency) {
  final type = cryptoCurrencyOrTokenToWalletType(currency);
  if (type != null) {
    return type;
  }

  try {
    return cryptoCurrencyOrTokenToWalletType(CryptoCurrency.fromString(currency.tag ?? ""));
  } catch (_) {
    return null;
  }
}

// Same rule as ExchangeViewModelBase.useSameWalletAddress: only software wallets send Lightning.
bool canFundDeposit(WalletInfo wallet, CryptoCurrency currency) =>
    currency is! ExternalCurrency &&
    (currency != CryptoCurrency.btcln || wallet.hardwareWalletType == null);
