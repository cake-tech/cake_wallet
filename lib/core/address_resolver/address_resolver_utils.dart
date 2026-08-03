import 'package:cake_wallet/core/address_resolver/unstoppable/unstoppable_address_provider.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';

class AddressResolverUtils {
  static Future<Map<CryptoCurrency, String>> resolveUnstoppableDomainFromText({
    required String raw,
    required List<CryptoCurrency> currencies,
  }) async {
    final domain = extractUnstoppableDomain(raw);
    if (domain.isEmpty) return {};

    final result = <CryptoCurrency, String>{};

    for (final currency in currencies) {
      final address =
          await UnstoppableAddressProvider.fetchUnstoppableDomainAddress(domain, currency.title);
      if (address.isNotEmpty) {
        result[currency] = address;
      }
    }

    return result;
  }

  static String extractUnstoppableDomain(String raw) {
// sort by length to avoid matching shorter tld instead of longer
    final domains = List<String>.from(UnstoppableAddressProvider.unstoppableDomains)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final tld in domains) {
      final pattern = RegExp(r'([A-Za-z0-9-]+)\.' + RegExp.escape(tld), caseSensitive: false);
      final match = pattern.firstMatch(raw);
      if (match != null) return match.group(0)!;
    }
    return '';
  }

  static Map<CryptoCurrency, String> extractAddressesFromText({
    required String raw,
    required List<CryptoCurrency> currencies,
    bool requireSurroundingWhitespaces = true,
  }) {
    final result = <CryptoCurrency, String>{};
    var text = raw;

    for (final currency in currencies) {
      final address = extractAddressByType(
        raw: text,
        type: currency,
        requireSurroundingWhitespaces: requireSurroundingWhitespaces,
      );

      if (address != null && address.isNotEmpty) {
        result[currency] = address;
        text = text.replaceFirst(address, '');
      }
    }

    return result;
  }

  static String? extractAddressByType({
    required String raw,
    required CryptoCurrency type,
    bool requireSurroundingWhitespaces = true,
  }) {
    var addressPattern = AddressValidator.getAddressFromStringPattern(type);
    if (addressPattern == null) {
      printV('Unknown pattern for $type');
      return null;
    }
    if (requireSurroundingWhitespaces) addressPattern = "$BEFORE_REGEX$addressPattern$AFTER_REGEX";
    final text = stripHtmlTags(raw);
    final match = RegExp(addressPattern, multiLine: true, caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return match.group(0)?.replaceAllMapped(RegExp('[^0-9a-zA-Z]|bitcoincash:|nano_|ban_'),
        (Match match) {
      String group = match.group(0)!;
      if (group.startsWith('bitcoincash:') ||
          group.startsWith('nano_') ||
          group.startsWith('ban_')) {
        return group;
      }
      return '';
    });
  }

  static bool isEmailFormat(String address) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(address);
  }

  static String stripHtmlTags(String value) {
    return value
        .replaceAll(RegExp(r'[\u2028\u2029]'), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .trim();
  }
}
