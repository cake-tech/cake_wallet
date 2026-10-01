import "package:cake_wallet/entities/provider_types.dart";
import "package:cake_wallet/exchange/exchange_provider_description.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_for_wallet_type.dart";

// These providers name chains, not chain IDs, and a guessed name can be another chain
// so each code is checked against the provider's list
const Map<int, Map<ExchangeProviderDescription, String>> evmExchangeProviderNetworkCodes = {
  // OP Mainnet
  10: {
    ExchangeProviderDescription.changeNow: "op",
    ExchangeProviderDescription.exolix: "OPTIMISM",
    ExchangeProviderDescription.letsExchange: "OPTIMISM",
    ExchangeProviderDescription.nearIntents: "op",
    ExchangeProviderDescription.sideShift: "optimism",
  },
  // HyperEVM
  999: {
    ExchangeProviderDescription.changeNow: "hyperevm",
    ExchangeProviderDescription.letsExchange: "HYPEEVM",
    ExchangeProviderDescription.sideShift: "hyperevm",
  },
  // Arc
  5042: {
    ExchangeProviderDescription.changeNow: "arc",
    ExchangeProviderDescription.sideShift: "arc",
  },
  // Monad
  143: {
    ExchangeProviderDescription.changeNow: "mon",
    ExchangeProviderDescription.letsExchange: "MONAD",
    ExchangeProviderDescription.nearIntents: "monad",
    ExchangeProviderDescription.sideShift: "monad",
  },
  // Plasma
  9745: {
    ExchangeProviderDescription.changeNow: "xpl",
    ExchangeProviderDescription.letsExchange: "XPL",
    ExchangeProviderDescription.nearIntents: "plasma",
    ExchangeProviderDescription.sideShift: "plasma",
  },
  // X Layer
  196: {
    ExchangeProviderDescription.nearIntents: "xlayer",
  },
  // Cronos
  25: {
    ExchangeProviderDescription.changeNow: "croevm",
    ExchangeProviderDescription.letsExchange: "CROEVM",
    ExchangeProviderDescription.sideShift: "cronos",
  },
  // Avalanche C-Chain
  43114: {
    ExchangeProviderDescription.changeNow: "cchain",
    ExchangeProviderDescription.exolix: "AVAXC",
    ExchangeProviderDescription.letsExchange: "AVAXC",
    ExchangeProviderDescription.nearIntents: "avax",
    ExchangeProviderDescription.sideShift: "avax",
    ExchangeProviderDescription.thorChain: "AVAX",
  },
};

// These providers only name chains
const Map<int, Map<ProviderType, String>> evmBuyProviderNetworkCodes = {
  // OP Mainnet
  10: {
    ProviderType.dfx: "Optimism",
    ProviderType.onramper: "optimism",
    ProviderType.robinhood: "OPTIMISM",
  },
  // HyperEVM
  999: {
    ProviderType.robinhood: "HYPEREVM",
  },
  // Monad
  143: {
    ProviderType.onramper: "monad",
  },
  // Plasma
  9745: {
    ProviderType.dfx: "Plasma",
    ProviderType.robinhood: "PLASMA",
  },
  // Ink
  57073: {
    ProviderType.onramper: "ink",
  },
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
  final code = evmExchangeProviderNetworkCodes[chainId]?[provider];
  if (code == null) {
    throw Exception("${provider.title} does not support ${currency.title} on this network");
  }

  return code;
}

bool isCurrencyNetworkSupported(CryptoCurrency currency, ExchangeProviderDescription provider) {
  final chainId = EvmNativeCurrencies.getAddedNetworkChainId(currency);
  return chainId == null || evmExchangeProviderNetworkCodes[chainId]?[provider] != null;
}

String? evmBuyProviderNetworkCode(CryptoCurrency currency, ProviderType provider) {
  final chainId = EvmNativeCurrencies.getAddedNetworkChainId(currency);
  return chainId == null ? null : evmBuyProviderNetworkCodes[chainId]?[provider];
}
