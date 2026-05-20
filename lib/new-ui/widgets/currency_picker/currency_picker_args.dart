import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

String chainNameForCurrency(CryptoCurrency c) {
  if (c == CryptoCurrency.btcln) return 'Lightning';
  final wt = cryptoCurrencyOrTokenToWalletType(c);
  return wt != null ? walletTypeToString(wt) : (c.tag ?? '');
}

class CurrencyPickerBalance {
  const CurrencyPickerBalance({required this.amount, this.fiat});

  final String amount;
  final String? fiat;
}

class CurrencyPickerArgs {
  const CurrencyPickerArgs({
    this.selected,
    required this.items,
    this.balanceByAsset,
    this.filterByNetwork,
    required this.onSelected,
    required this.pickerContext,
    required this.symbolResolver,
  });

  final String pickerContext;
  final CryptoCurrency? selected;
  final List<CryptoCurrency> items;
  final WalletType? filterByNetwork;
  final void Function(CryptoCurrency) onSelected;
  final String Function(CryptoCurrency) symbolResolver;
  final Map<CryptoCurrency, CurrencyPickerBalance>? balanceByAsset;

  bool get isPreFiltered => filterByNetwork != null;
}
