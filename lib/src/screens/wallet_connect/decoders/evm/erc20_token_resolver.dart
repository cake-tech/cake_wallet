import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/calculate_fiat_amount.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:intl/intl.dart';

class Erc20TokenResolver {
  Erc20TokenResolver(this.appStore);

  final AppStore appStore;

  /// `type(uint160).max` — the Permit2 "infinite allowance" sentinel.
  static final BigInt _uint160Max = (BigInt.one << 160) - BigInt.one;

  /// Largest Unix timestamp we'll render as a date (end of year 9999). Anything
  /// larger is almost certainly garbage / not a real timestamp.
  static final BigInt _maxTimestampSeconds = BigInt.from(253402300799);

  bool isUnlimitedAmount(BigInt amount) =>
      amount == _uint160Max || amount >= BigInt.from(2).pow(200);

  Future<Erc20Token?> resolve(String contractAddress) async {
    final wallet = appStore.wallet;
    if (wallet == null || evm == null) return null;

    final target = contractAddress.toLowerCase();

    try {
      final known = evm!.getERC20Currencies(wallet);
      for (final token in known) {
        if (token.contractAddress.toLowerCase() == target) return token;
      }
    } catch (e) {
      printV('Erc20TokenResolver: failed to read wallet ERC-20 list: $e');
    }

    try {
      return await evm!
          .getErc20Token(wallet, contractAddress)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      printV('Erc20TokenResolver: failed to fetch ERC-20 metadata for $contractAddress: $e');
      return null;
    }
  }

  String formatAmount(BigInt rawAmount, Erc20Token? token) {
    if (isUnlimitedAmount(rawAmount)) return S.current.wc_unlimited;
    if (token == null) return rawAmount.toString();

    final decimals = token.decimal;
    if (decimals <= 0) return rawAmount.toString();

    final divisor = BigInt.from(10).pow(decimals);
    final whole = rawAmount ~/ divisor;
    final remainder = rawAmount % divisor;
    if (remainder == BigInt.zero) return whole.toString();

    final fractional = remainder.toString().padLeft(decimals, '0');
    final trimmed = fractional.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
  }

  String formatNative(double value) {
    if (value == 0) return '0';
    if (value >= 0.0001) return value.toStringAsFixed(6);
    return value.toStringAsExponential(4);
  }

  String? fiatFor(CryptoCurrency currency, String cryptoAmount) {
    if (currency == CryptoCurrency.btc) return null;
    if (cryptoAmount.isEmpty || cryptoAmount == S.current.wc_unlimited) return null;
    try {
      final fiatStore = getIt.get<FiatConversionStore>();
      final price = fiatStore.prices[currency];
      if (price == null || price <= 0) return null;
      final fiatSymbol = appStore.settingsStore.fiatCurrency.title;
      final value = calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
      if (value.isEmpty || value == '0.00') return null;
      return '~ $value $fiatSymbol';
    } catch (_) {
      return null;
    }
  }

  String symbolOrShort(Erc20Token? token, String contractAddress) {
    if (token != null && token.symbol.isNotEmpty) return token.symbol.toUpperCase();
    return shortAddress(contractAddress);
  }

  String shortAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }

  /// Renders a Unix-epoch-seconds value as a local date+time. Values that are
  /// zero, negative or implausibly large are returned verbatim so we never
  /// show a bogus date for a field that only looked like a timestamp.
  String formatTimestamp(BigInt? seconds) {
    if (seconds == null) return '';
    if (seconds <= BigInt.zero || seconds > _maxTimestampSeconds) {
      return seconds.toString();
    }
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
      return DateFormat.yMMMd().add_Hm().format(dt);
    } catch (_) {
      return seconds.toString();
    }
  }
}
