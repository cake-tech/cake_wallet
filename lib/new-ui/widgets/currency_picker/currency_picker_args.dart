import 'package:cake_wallet/evm/evm.dart';
import "package:cw_core/amount/money.dart";
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency/fiat_currency.dart";
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/currency_groups.dart';
import 'package:cw_core/wallet_type.dart';

String chainNameForCurrency(CryptoCurrency c) {
  if (c == CryptoCurrency.btcln) return 'Lightning';
  final wt = cryptoCurrencyOrTokenToWalletType(c);
  return wt != null ? walletTypeToString(wt) : (c.tag ?? '');
}

final Set<String> _stablecoinSymbols = {
  for (final c in CryptoCurrency.all)
    if (c.groups.contains(CurrencyGroups.stablecoin)) c.title.toUpperCase(),
};

bool isTrustedStablecoin(CryptoCurrency c) =>
    (c.groups.contains(CurrencyGroups.stablecoin) ||
        _stablecoinSymbols.contains(c.title.toUpperCase())) &&
    !c.isPotentialScam;

const _kEvmDefaultTokenNatives = <CryptoCurrency>[
  CryptoCurrency.baseEth,
  CryptoCurrency.arbEth,
  CryptoCurrency.maticpoly,
];

void appendEvmDefaultTokens(List<CryptoCurrency> into) {
  if (evm == null) return;
  String keyFor(CryptoCurrency c) {
    final wt = cryptoCurrencyOrTokenToWalletType(c);
    final chain = wt?.toString() ?? (c.tag ?? '').toUpperCase();
    return '${c.title.toUpperCase()}|$chain';
  }

  final seen = <String>{for (final c in into) keyFor(c)};
  for (final native in _kEvmDefaultTokenNatives) {
    final chainId = getChainIdByCryptoCurrency(native);
    if (chainId == null) continue;
    for (final t in evm!.getDefaultTokensByChainId(chainId)) {
      if (seen.add(keyFor(t))) into.add(t);
    }
  }
}

class CurrencyPickerBalance {
  const CurrencyPickerBalance({required this.amount, this.fiat});

  final Money amount;
  final Money? fiat;
}

enum RecentsSource { none, trades, orders }

class CurrencyPickerArgs {
  const CurrencyPickerArgs({
    required this.items,
    required this.fiatCurrency,
    required this.onSelected,
    this.selected,
    this.balanceByAsset,
    this.filterByNetwork,
    this.recentsSource = RecentsSource.none,
  });

  final CryptoCurrency? selected;
  final FiatCurrency fiatCurrency;
  final List<CryptoCurrency> items;
  final WalletType? filterByNetwork;
  final void Function(CryptoCurrency) onSelected;
  final Map<CryptoCurrency, CurrencyPickerBalance>? balanceByAsset;
  final RecentsSource recentsSource;

  bool get isPreFiltered => filterByNetwork != null;
}
