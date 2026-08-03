import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';

abstract class AddressLookupProvider {
  AddressSource get source;

  List<CryptoCurrency> get supportedCurrencies;

  bool isEnabled(SettingsStore settingsStore);

  bool canHandle(String query);

  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  });
}
