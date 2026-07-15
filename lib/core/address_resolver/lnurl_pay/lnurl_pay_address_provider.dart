import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/lnurl_pay/lnurlpay_record.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';

class LNUrlPayAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.lnurlPay;

  @override
  List<CryptoCurrency> get supportedCurrencies => [CryptoCurrency.btcln];

  @override
  bool canHandle(String q) =>
      q.contains('.') && q.contains('@'); // LNURL-pay handle example: user@domain.com

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsLNUrl;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    try {
      if (wallet.type != WalletType.bitcoin) return [];

      final formattedName = query.trim();
      if (formattedName.isEmpty) return [];

      final result = <CryptoCurrency, String>{};

      for (final currency in currencies) {
        if (!supportedCurrencies.contains(currency)) continue;

        final record = await LNUrlPayRecord.fetchAddressAndName(
          formattedName: formattedName,
          currency: currency,
        );

        if (record != null && record.address.isNotEmpty) {
          result[currency] = record.address;
        }
      }

      if (result.isEmpty) return [];

      return [
        ParsedAddress(
          parsedAddressByCurrencyMap: result,
          addressSource: AddressSource.lnurlPay,
          handle: formattedName,
          profileName: formattedName,
        ),
      ];
    } catch (e) {
      printV('[address resolver] Error resolving LNURL-pay address: $e');
      return [];
    }
  }
}
