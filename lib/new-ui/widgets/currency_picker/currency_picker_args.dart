import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/currency_groups.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/spl_token.dart";
import "package:cw_core/tron_token.dart";
import "package:cw_core/wallet_type.dart";

String chainNameForCurrency(CryptoCurrency c) {
  if (c == CryptoCurrency.btcln) {
    return "Lightning";
  }
  final wt = cryptoCurrencyOrTokenToWalletType(c);
  return wt != null ? walletTypeToString(wt) : (c.tag ?? "");
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
  if (evm == null) {
    return;
  }
  String keyFor(CryptoCurrency c) {
    final wt = cryptoCurrencyOrTokenToWalletType(c);
    final chain = wt?.toString() ?? (c.tag ?? "").toUpperCase();
    return "${c.title.toUpperCase()}|$chain";
  }

  final seen = <String>{for (final c in into) keyFor(c)};
  for (final native in _kEvmDefaultTokenNatives) {
    final chainId = getChainIdByCryptoCurrency(native);
    if (chainId == null) {
      continue;
    }
    for (final t in evm!.getDefaultTokensByChainId(chainId)) {
      if (seen.add(keyFor(t))) {
        into.add(t);
      }
    }
  }
}

class CurrencyPickerBalance {
  const CurrencyPickerBalance({required this.amount, this.fiat, this.fiatValue});

  final String amount;
  final String? fiat;
  final double? fiatValue;
}

String? _assetAddressKey(CryptoCurrency c) {
  if (c is Erc20Token) {
    return c.contractAddress.toLowerCase();
  }
  if (c is TronToken) {
    return c.contractAddress.toLowerCase();
  }
  if (c is SPLToken) {
    return c.mintAddress.toLowerCase();
  }
  return null;
}

CurrencyPickerBalance? balanceForAsset(
  Map<CryptoCurrency, CurrencyPickerBalance>? balances,
  CryptoCurrency asset,
) {
  if (balances == null || balances.isEmpty) {
    return null;
  }

  final direct = balances[asset];
  if (direct != null) {
    return direct;
  }

  final addressKey = _assetAddressKey(asset);
  if (addressKey != null) {
    for (final entry in balances.entries) {
      if (_assetAddressKey(entry.key) == addressKey) {
        return entry.value;
      }
    }
    return null;
  }

  final title = asset.title.toUpperCase();
  CurrencyPickerBalance? byTitle;
  for (final entry in balances.entries) {
    if (entry.key.title.toUpperCase() == title) {
      if (byTitle != null) {
        return null;
      }
      byTitle = entry.value;
    }
  }
  return byTitle;
}

enum RecentsSource { none, trades, orders }

class CurrencyPickerArgs {
  const CurrencyPickerArgs({
    this.selected,
    required this.items,
    this.balanceByAsset,
    this.filterByNetwork,
    required this.onSelected,
    required this.symbolResolver,
    this.recentsSource = RecentsSource.none,
    this.useSingleNetworkLayout = false,
  });

  final CryptoCurrency? selected;
  final List<CryptoCurrency> items;
  final WalletType? filterByNetwork;
  final void Function(CryptoCurrency) onSelected;
  final String Function(CryptoCurrency) symbolResolver;
  final Map<CryptoCurrency, CurrencyPickerBalance>? balanceByAsset;
  final RecentsSource recentsSource;
  final bool useSingleNetworkLayout;
}
