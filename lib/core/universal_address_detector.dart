import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/core/address_validator.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';

class AddressDetectionResult {
  AddressDetectionResult({
    required this.address,
    this.detectedCurrency,
    this.detectedWalletType,
    this.amount,
    this.note,
    this.scheme,
    this.pjUri,
    this.callbackUrl,
    this.callbackMessage,
    required this.isValid,
    this.errorMessage,
  });

  final String address;
  final CryptoCurrency? detectedCurrency;
  final WalletType? detectedWalletType;
  final String? amount;
  final String? note;
  final String? scheme;
  final String? pjUri;
  final String? callbackUrl;
  final String? callbackMessage;
  final bool isValid;
  final String? errorMessage;
}

/// Universal address detector that can identify cryptocurrency addresses from various formats
class UniversalAddressDetector {
  /// Detects cryptocurrency address from various input formats
  /// Supports: raw addresses, URIs, and QR codes
  static AddressDetectionResult detectAddress(String input) {
    if (input.trim().isEmpty) {
      return AddressDetectionResult(
        address: '',
        detectedCurrency: null,
        isValid: false,
        errorMessage: 'Empty input provided',
      );
    }

    // Try to parse as URI first
    final uriResult = _detectFromUri(input);
    if (uriResult.isValid) return uriResult;

    // Try to detect from raw address patterns
    final rawAddressResult = _detectFromRawAddress(input);
    if (rawAddressResult.isValid) return rawAddressResult;

    return AddressDetectionResult(
      address: input,
      detectedCurrency: null,
      isValid: false,
      errorMessage: 'Unable to detect valid cryptocurrency address',
    );
  }

  /// Detects address from URI format (e.g., bitcoin:address?amount=0.001)
  static AddressDetectionResult _detectFromUri(String input) {
    try {
      final uri = Uri.parse(input);

      final paymentRequest = PaymentRequest.fromUri(uri);

      // Determine currency from scheme
      final currency = CryptoCurrency.fromString(uri.scheme.toLowerCase());

      return AddressDetectionResult(
        address: paymentRequest.address,
        detectedCurrency: currency,
        detectedWalletType: cryptoCurrencyToWalletType(currency),
        amount: paymentRequest.amount,
        note: paymentRequest.note,
        scheme: paymentRequest.scheme,
        pjUri: paymentRequest.pjUri,
        callbackUrl: paymentRequest.callbackUrl,
        callbackMessage: paymentRequest.callbackMessage,
        isValid: true,
      );
    } catch (e) {
      return AddressDetectionResult(
        address: input,
        detectedCurrency: null,
        isValid: false,
        errorMessage: 'Failed to parse URI: $e',
      );
    }
  }

  /// Detect address from raw address patterns
  static AddressDetectionResult _detectFromRawAddress(String input) {
    final cleanInput = input.trim();

    // Detection patterns ordered by specificity (most specific first)
    final detectionPatterns = [
      // Lightning Network
      _DetectionPattern(
        pattern: RegExp(r'^(lnbc|LNBC)[a-km-zA-HJ-NP-Z1-9]{1,}[a-zA-Z0-9]+$'),
        currency: CryptoCurrency.btcln,
      ),
      
      // Lightning Address (email format)
      _DetectionPattern(
        pattern: RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
        currency: CryptoCurrency.btcln,
      ),
      
      // LNURL format
      _DetectionPattern(
        pattern: RegExp(r'^(LNURL|lnurl)[a-zA-Z0-9]+$', caseSensitive: false),
        currency: CryptoCurrency.btcln,
      ),

      // Bitcoin (P2PKH, P2SH, Bech32, Silent Payments)
      _DetectionPattern(
        pattern: RegExp('^(?:'
            '1[a-km-zA-HJ-NP-Z1-9]{25,34}'
            '|3[a-km-zA-HJ-NP-Z1-9]{25,34}'
            '|(?:bc|tb)1q[ac-hj-np-z02-9]{25,39}'
            '|(?:bc|tb)1p(?:[ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59}|[ac-hj-np-z02-9]{8,89})'
            '|(?:bc|tb)1q[ac-hj-np-z02-9]{40,80}'
            '|${AddressValidator.silentPaymentAddressPatternMainnet}'
            '|${AddressValidator.silentPaymentAddressPatternTestnet}'
            ')\$'),
        currency: CryptoCurrency.btc,
      ),

      // Litecoin (Legacy, Bech32, MWEB)
      _DetectionPattern(
        pattern: RegExp('^(?:'
            'L[a-km-zA-HJ-NP-Z1-9]{25,34}'
            '|[3M][a-km-zA-HJ-NP-Z1-9]{25,34}'
            '|ltc1q[ac-hj-np-z02-9]{25,39}'
            '|ltc1p(?:[ac-hj-np-z02-9]{39}|[ac-hj-np-z02-9]{59}|[ac-hj-np-z02-9]{8,89})'
            '|ltc1q[ac-hj-np-z02-9]{40,80}'
            '|${AddressValidator.mWebAddressPattern}'
            ')\$'),
        currency: CryptoCurrency.ltc,
      ),

      // Bitcoin Cash
      _DetectionPattern(
        pattern: RegExp(r'^(q|p)[a-z0-9]{41}$'),
        currency: CryptoCurrency.bch,
      ),

      // Ethereum
      _DetectionPattern(
        pattern: RegExp(r'^0x[a-fA-F0-9]{40}$'),
        currency: CryptoCurrency.eth,
      ),

      // Nano
      _DetectionPattern(
        pattern: RegExp(r'^nano_[a-km-zA-HJ-NP-Z1-9]{60}$'),
        currency: CryptoCurrency.nano,
      ),

      // Banano
      _DetectionPattern(
        pattern: RegExp(r'^ban_[a-km-zA-HJ-NP-Z1-9]{60}$'),
        currency: CryptoCurrency.banano,
      ),

      // Tron
      _DetectionPattern(
        pattern: RegExp(r'^T[a-km-zA-HJ-NP-Z1-9]{33}$'),
        currency: CryptoCurrency.trx,
      ),

      // Zano alias
      _DetectionPattern(
        pattern: RegExp(r'^@[\w\d.-]+$'),
        currency: CryptoCurrency.zano,
      ),

      // Monero (standard) - 95 characters
      _DetectionPattern(
        pattern: RegExp(r'^4[a-km-zA-HJ-NP-Z1-9]{94}$'),
        currency: CryptoCurrency.xmr,
      ),

      // Monero (integrated) - 95 characters
      _DetectionPattern(
        pattern: RegExp(r'^8[a-km-zA-HJ-NP-Z1-9]{94}$'),
        currency: CryptoCurrency.xmr,
      ),

      // Wownero - 97 characters
      _DetectionPattern(
        pattern: RegExp(r'^W[a-km-zA-HJ-NP-Z1-9]{96}$'),
        currency: CryptoCurrency.wow,
      ),

      // Zano (long addresses) - 97 characters
      _DetectionPattern(
        pattern: RegExp(r'^Z[a-km-zA-HJ-NP-Z1-9]{96}$'),
        currency: CryptoCurrency.zano,
      ),

      // Decred
      _DetectionPattern(
        pattern: RegExp(r'^(D|T|S)[ksecS][a-km-zA-HJ-NP-Z1-9]+$'),
        currency: CryptoCurrency.dcr,
      ),

      // Dogecoin P2PKH
      _DetectionPattern(
        pattern: RegExp(r'^D[a-km-zA-HJ-NP-Z1-9]{25,34}$'),
        currency: CryptoCurrency.doge,
      ),

      // Solana (Base58 format)
      _DetectionPattern(
        pattern: RegExp(r'^[1-9A-HJ-NP-Za-km-z]{43,44}$'),
        currency: CryptoCurrency.sol,
      ),
    ];

    // Test each pattern in order of specificity
    for (final pattern in detectionPatterns) {
      if (pattern.pattern.hasMatch(cleanInput)) {
        return AddressDetectionResult(
          address: cleanInput,
          detectedCurrency: pattern.currency,
          detectedWalletType: cryptoCurrencyToWalletType(pattern.currency),
          isValid: true,
        );
      }
    }

    return AddressDetectionResult(
      address: cleanInput,
      detectedCurrency: null,
      isValid: false,
    );
  }
}

class _DetectionPattern {
  const _DetectionPattern({
    required this.pattern,
    required this.currency,
  });

  final RegExp pattern;
  final CryptoCurrency currency;
}
