import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';

abstract class AddressLookupProvider {
  AddressSource get source;

  List<CryptoCurrency> get supportedCurrencies;

  /// Whether this provider is able to look up an address for [currency].
  ///
  /// Defaults to a membership test against [supportedCurrencies], which keeps
  /// the behaviour of currency-scoped providers (LNURL-pay, Zano, Zcash, ...)
  /// exactly as it is.
  ///
  /// [CryptoCurrency] does not override `==`, so that membership test is
  /// identity based and can never match a currency that is built at runtime -
  /// most importantly `Erc20Token`, which overrides `==` on its contract
  /// address. Providers that support such currencies must override this
  /// predicate instead of trying to extend the const [supportedCurrencies]
  /// list.
  bool supportsCurrency(CryptoCurrency currency) => supportedCurrencies.contains(currency);

  bool isEnabled(SettingsStore settingsStore);

  bool canHandle(String query);

  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  });
}
