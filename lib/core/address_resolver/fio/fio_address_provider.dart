import 'dart:convert';

import 'package:cake_wallet/core/address_resolver/address_lookup_provider.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/core/address_resolver/parsed_address.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cw_core/wallet_base.dart';

class FioAddressProvider extends AddressLookupProvider {
  @override
  AddressSource get source => AddressSource.fio;

  @override
  List<CryptoCurrency> get supportedCurrencies => AddressValidator.reliableValidateCurrencies;

  @override
  bool canHandle(String q) =>
      !q.startsWith('@') &&
      q.contains('@') &&
      !q.contains('.'); // FIO handle example: username@domain

  @override
  bool isEnabled(SettingsStore settingsStore) => settingsStore.lookupsFio;

  @override
  Future<List<ParsedAddress>> resolve({
    required String query,
    required List<CryptoCurrency> currencies,
    required WalletBase wallet,
  }) async {
    final Map<CryptoCurrency, String> result = {};
    try {
      final bool isFioRegistered = await FioAddressProvider.checkAvail(query);
      if (!isFioRegistered) return [];

      for (final cur in currencies) {
        final address = await FioAddressProvider.getPubAddress(query, cur.title);
        if (address != null && address.isNotEmpty) {
          result[cur] = address;
        }
      }

      if (result.isNotEmpty) {
        return [
          ParsedAddress(
              parsedAddressByCurrencyMap: result, addressSource: AddressSource.fio, handle: query)
        ];
      }
      return [];
    } catch (e) {
      printV('FioAddressProvider.resolve error: $e');
      return [];
    }
  }

  static const _apiAuthority = 'fio.blockpane.com';
  static const _availCheck = '/v1/chain/avail_check';
  static const _getAddress = '/v1/chain/get_pub_address';

  static Future<bool> checkAvail(String fioAddress) async {
    bool isFioRegistered = false;
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{"fio_name": fioAddress};

    final uri = Uri.https(_apiAuthority, _availCheck);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      return isFioRegistered;
    }

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;
    isFioRegistered = responseJSON['is_registered'] as int == 1;

    return isFioRegistered;
  }

  static Future<String?> getPubAddress(String fioAddress, String token) async {
    final headers = {'Content-Type': 'application/json'};
    final body = <String, String>{
      "fio_address": fioAddress,
      "chain_code": token.toUpperCase(),
      "token_code": token.toUpperCase(),
    };

    final uri = Uri.https(_apiAuthority, _getAddress);
    final response = await ProxyWrapper().post(
      clearnetUri: uri,
      headers: headers,
      body: json.encode(body),
    );

    final responseJSON = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 400) {
      final error = responseJSON['error'] as String;
      final message = responseJSON['message'] as String;
      printV('${error}\n$message');
      return null;
    }

    if (response.statusCode != 200) {
      final String message = responseJSON['message'] as String? ?? 'Unknown error';

      printV('Error fetching public address for token $token: $message');
      return null;
    }

    final String pubAddress = responseJSON['public_address'] as String? ?? '';

    if (pubAddress.isNotEmpty) {
      return pubAddress;
    }

    return null;
  }
}
