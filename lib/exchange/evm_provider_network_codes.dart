import "package:cake_wallet/entities/provider_types.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";

class EvmNetworkProviderCodes {
  const EvmNetworkProviderCodes({
    this.exchange = const {},
    this.nativeTickers = const {},
    this.buy = const {},
  });

  final Map<ExchangeProviderDescription, String> exchange;

  final Map<ExchangeProviderDescription, String> nativeTickers;

  final Map<ProviderType, String> buy;
}

// These providers name chains, not chain IDs, and a guessed name can be another chain
// so each code is checked against the provider's list
const Map<int, EvmNetworkProviderCodes> evmNetworkProviderCodes = {
  // OP Mainnet
  10: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "op",
      ExchangeProviderDescription.exolix: "OPTIMISM",
      ExchangeProviderDescription.letsExchange: "OPTIMISM",
      ExchangeProviderDescription.nearIntents: "op",
      ExchangeProviderDescription.sideShift: "optimism",
    },
    buy: {
      ProviderType.dfx: "Optimism",
      ProviderType.onramper: "optimism",
      ProviderType.robinhood: "OPTIMISM",
    },
  ),
  // HyperEVM
  999: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "hyperevm",
      ExchangeProviderDescription.letsExchange: "HYPEEVM",
      ExchangeProviderDescription.sideShift: "hyperevm",
    },
    buy: {
      ProviderType.robinhood: "HYPEREVM",
    },
  ),
  // Arc
  5042: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "arc",
      ExchangeProviderDescription.sideShift: "arc",
    },
  ),
  // Monad
  143: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "mon",
      ExchangeProviderDescription.letsExchange: "MONAD",
      ExchangeProviderDescription.nearIntents: "monad",
      ExchangeProviderDescription.sideShift: "monad",
    },
    nativeTickers: {
      ExchangeProviderDescription.changeNow: "monad",
    },
    buy: {
      ProviderType.onramper: "monad",
    },
  ),
  // Plasma
  9745: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "xpl",
      ExchangeProviderDescription.letsExchange: "XPL",
      ExchangeProviderDescription.nearIntents: "plasma",
      ExchangeProviderDescription.sideShift: "plasma",
    },
    buy: {
      ProviderType.dfx: "Plasma",
      ProviderType.robinhood: "PLASMA",
    },
  ),
  // X Layer
  196: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.nearIntents: "xlayer",
    },
  ),
  // Cronos
  25: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "croevm",
      ExchangeProviderDescription.letsExchange: "CROEVM",
      ExchangeProviderDescription.sideShift: "cronos",
    },
  ),
  // Avalanche C-Chain
  43114: EvmNetworkProviderCodes(
    exchange: {
      ExchangeProviderDescription.changeNow: "cchain",
      ExchangeProviderDescription.exolix: "AVAXC",
      ExchangeProviderDescription.letsExchange: "AVAXC",
      ExchangeProviderDescription.nearIntents: "avax",
      ExchangeProviderDescription.sideShift: "avax",
      ExchangeProviderDescription.thorChain: "AVAX",
    },
  ),
  // Ink
  57073: EvmNetworkProviderCodes(
    buy: {
      ProviderType.onramper: "ink",
    },
  ),
};

String? evmExchangeProviderNetworkCode(
  CryptoCurrency currency,
  ExchangeProviderDescription provider,
) {
  final chainId = EvmNativeCurrencies.getAddedNetworkChainId(currency);
  if (chainId == null) {
    return null;
  }

  // Sending the tag or title instead would let the provider read it as another chain
  final code = evmNetworkProviderCodes[chainId]?.exchange[provider];
  if (code == null) {
    throw Exception("${provider.title} does not support ${currency.title} on this network");
  }

  return code;
}

bool isCurrencyNetworkSupported(CryptoCurrency currency, ExchangeProviderDescription provider) {
  final chainId = EvmNativeCurrencies.getAddedNetworkChainId(currency);
  return chainId == null || evmNetworkProviderCodes[chainId]?.exchange[provider] != null;
}

String? evmBuyProviderNetworkCode(CryptoCurrency currency, ProviderType provider) {
  final chainId = EvmNativeCurrencies.getAddedNetworkChainId(currency);
  return chainId == null ? null : evmNetworkProviderCodes[chainId]?.buy[provider];
}

String? evmNativeCurrencyTicker(CryptoCurrency currency, ExchangeProviderDescription provider) {
  if (!EvmNativeCurrencies.isAddedNetworkRaw(currency.raw)) {
    return null;
  }

  final chainId = EvmNativeCurrencies.addedNetworkChainIdFromRaw(currency.raw);
  return evmNetworkProviderCodes[chainId]?.nativeTickers[provider];
}
