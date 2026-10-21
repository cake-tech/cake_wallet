import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/calculate_fiat_amount.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:intl/intl.dart";

class Erc20TokenResolver {
  Erc20TokenResolver(this.appStore);

  final AppStore? appStore;

  static final BigInt _uint160Max = (BigInt.one << 160) - BigInt.one;

  static final BigInt _maxTimestampSeconds = BigInt.from(253402300799);

  bool isUnlimitedAmount(BigInt amount) =>
      amount == _uint160Max || amount >= BigInt.from(2).pow(200);

  Future<Erc20Token?> resolve(String contractAddress) async {
    final wallet = appStore?.wallet;
    if (wallet == null || evm == null) {
      return null;
    }

    final target = contractAddress.toLowerCase();

    try {
      final known = evm!.getERC20Currencies(wallet);
      for (final token in known) {
        if (token.contractAddress.toLowerCase() == target) {
          return token;
        }
      }
    } catch (e) {
      printV("Erc20TokenResolver: failed to read wallet ERC-20 list: $e");
    }

    try {
      return await evm!
          .getErc20Token(wallet, contractAddress)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      printV("Erc20TokenResolver: failed to fetch ERC-20 metadata for $contractAddress: $e");
      return null;
    }
  }

  String formatAmount(BigInt rawAmount, Erc20Token? token) {
    if (isUnlimitedAmount(rawAmount)) {
      return S.current.wc_unlimited;
    }
    if (token == null) {
      return rawAmount.toString();
    }
    return formatUnits(rawAmount, token.decimal);
  }

  String formatNativeAmount(BigInt wei) => formatUnits(wei, 18);

  String formatUnits(BigInt rawAmount, int decimals) {
    if (decimals <= 0) {
      return rawAmount.toString();
    }

    final divisor = BigInt.from(10).pow(decimals);
    final whole = rawAmount ~/ divisor;
    final remainder = rawAmount % divisor;
    if (remainder == BigInt.zero) {
      return whole.toString();
    }

    final fractional = remainder.toString().padLeft(decimals, "0");
    final trimmed = fractional.replaceFirst(RegExp(r"0+$"), "");
    return trimmed.isEmpty ? whole.toString() : "$whole.$trimmed";
  }

  String displayName(Erc20Token? token, String symbol) {
    if (token != null && token.name.isNotEmpty) {
      return "${token.name} ($symbol)";
    }
    return symbol;
  }

  String? fiatFor(CryptoCurrency currency, String cryptoAmount) {
    if (appStore == null) {
      return null;
    }
    if (cryptoAmount.isEmpty || cryptoAmount == S.current.wc_unlimited) {
      return null;
    }
    try {
      final fiatStore = getIt.get<FiatConversionStore>();
      final price = fiatStore.prices[currency];
      if (price == null || price <= 0) {
        return null;
      }
      final fiatSymbol = appStore!.settingsStore.fiatCurrency.title;
      final value = calculateFiatAmount(price: price, cryptoAmount: cryptoAmount);
      if (value.isEmpty || value == "0.00") {
        return null;
      }
      return "~ $value $fiatSymbol";
    } catch (e) {
      printV("Erc20TokenResolver: fiat conversion failed for ${currency.title}: $e");
      return null;
    }
  }

  String symbolOrShort(Erc20Token? token, String contractAddress) {
    if (token != null && token.symbol.isNotEmpty) {
      return token.symbol.toUpperCase();
    }
    return shortAddress(contractAddress);
  }

  String shortAddress(String address) {
    if (address.length <= 10) {
      return address;
    }
    return "${address.substring(0, 6)}…${address.substring(address.length - 4)}";
  }

  String formatTimestamp(BigInt? seconds) {
    if (seconds == null) {
      return "";
    }
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
