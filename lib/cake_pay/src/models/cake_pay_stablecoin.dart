import "package:cake_wallet/cake_pay/src/models/cake_pay_payment_method.dart";
import "package:collection/collection.dart";
import "package:cw_core/crypto_currency.dart";

class StablecoinPaymentOption {
  const StablecoinPaymentOption({required this.method, required this.networks});

  final CakePayPaymentMethod method;
  final List<StablecoinNetwork> networks;

  StablecoinNetwork? findNetwork(CryptoCurrency nativeCurrency) =>
      networks.firstWhereOrNull((network) => network.nativeCurrency == nativeCurrency);

  static List<StablecoinPaymentOption> listFromMap(Map<String, dynamic> paymentData) => [
        for (final method in [CakePayPaymentMethod.USDC, CakePayPaymentMethod.USDT])
          if (paymentData[method.name]
              case {"requires_quote": true, "networks": final List<dynamic> networks}
              when networks.isNotEmpty)
            StablecoinPaymentOption(
              method: method,
              networks: networks
                  .map((network) => StablecoinNetwork.fromMap(network as Map<String, dynamic>))
                  .toList(),
            ),
      ];
}

class StablecoinNetwork {
  const StablecoinNetwork({required this.id});

  factory StablecoinNetwork.fromMap(Map<String, dynamic> map) =>
      StablecoinNetwork(id: map["chain"] as String);

  final String id;

  static const _nativeCurrencies = {
    "ethereum": CryptoCurrency.eth,
    "base": CryptoCurrency.baseEth,
    "arbitrum": CryptoCurrency.arbEth,
    "polygon": CryptoCurrency.maticpoly,
    "bsc": CryptoCurrency.bnb,
    "tron": CryptoCurrency.trx,
    "solana": CryptoCurrency.sol,
  };

  static bool supportsNetwork(CryptoCurrency nativeCurrency) =>
      _nativeCurrencies.containsValue(nativeCurrency);

  CryptoCurrency? get nativeCurrency => _nativeCurrencies[id];
}

class CakePayStablecoinQuote {
  const CakePayStablecoinQuote({
    required this.address,
    required this.amount,
    this.contract,
    this.offeredUntil,
  });

  factory CakePayStablecoinQuote.fromMap(Map<String, dynamic> map) {
    final offeredUntil = map["offered_until"] as int;

    return CakePayStablecoinQuote(
      address: map["address"] as String,
      amount: map["amount"] as String,
      contract: map["contract"] as String?,
      offeredUntil: offeredUntil > 0 ? DateTime.fromMillisecondsSinceEpoch(offeredUntil) : null,
    );
  }

  final String address;
  final String amount;
  final String? contract;
  final DateTime? offeredUntil;
}
