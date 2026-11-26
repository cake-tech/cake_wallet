import "package:cake_wallet/entities/calculate_fiat_amount.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_calldata.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/evm/evm_selectors.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/erc20_token.dart";
import "package:cw_core/format_fixed.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:intl/intl.dart";

class Erc20TokenResolver {
  Erc20TokenResolver(this.appStore, {this.fiatConversionStore});

  final AppStore? appStore;
  final FiatConversionStore? fiatConversionStore;

  static final _maxTimestampSeconds = BigInt.from(253402300799);

  static const _maxDecimals = 77;

  static const _maxNameLength = 64;

  bool isUnlimitedAmount(BigInt amount) =>
      amount == EvmCalldata.uint160Max || amount >= BigInt.two.pow(200);

  Future<Erc20Token?> resolve(String contractAddress) async {
    final token = await _lookUp(contractAddress);
    if (token == null || token.decimal < 0 || token.decimal > _maxDecimals) {
      return null;
    }
    return token;
  }

  Future<Erc20Token?> _lookUp(String contractAddress) async {
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

  bool isKnown(String contractAddress, {required int? chainId}) {
    final target = contractAddress.toLowerCase();
    if (EvmSelectors.isWrappedNative(chainId, target)) {
      return true;
    }

    final wallet = appStore?.wallet;
    if (wallet == null || evm == null) {
      return false;
    }

    try {
      final isDefault =
          chainId != null &&
          evm!
              .getDefaultTokensByChainId(chainId)
              .any((token) => token.contractAddress.toLowerCase() == target);
      if (isDefault) {
        return true;
      }

      return evm!
          .getERC20Currencies(wallet)
          .any(
            (token) =>
                token.contractAddress.toLowerCase() == target &&
                token.enabled &&
                !token.isPotentialScam,
          );
    } catch (e) {
      printV("Erc20TokenResolver: known-token check failed for $contractAddress: $e");
      return false;
    }
  }

  String formatAmount(BigInt rawAmount, Erc20Token? token) {
    if (isUnlimitedAmount(rawAmount)) {
      return S.current.wc_unlimited;
    }
    if (token == null) {
      return rawAmount.toString();
    }
    return formatFixed(rawAmount, token.decimal);
  }

  String formatNativeAmount(BigInt wei) => formatFixed(wei, 18);

  List<WCDecodedRow> tokenRows(
    Erc20Token? token,
    String contractAddress, {
    required bool isKnown,
  }) => [
    if (token != null)
      WCDecodedRow(
        label: S.current.wc_token,
        value: displayName(token, symbolOrShort(token, contractAddress)),
      ),
    if (token == null || !isKnown)
      WCDecodedRow(
        label: S.current.wc_token,
        value: contractAddress,
        kind: WCDecodedRowKind.address,
      ),
  ];

  String amountText(BigInt rawAmount, Erc20Token? token, String contractAddress) =>
      "${formatAmount(rawAmount, token)} ${symbolOrShort(token, contractAddress)}";

  String displayName(Erc20Token? token, String symbol) {
    if (token != null && token.name.isNotEmpty) {
      return "${_capped(token.name)} ($symbol)";
    }
    return symbol;
  }

  String? fiatFor(CryptoCurrency currency, String cryptoAmount) {
    if (appStore == null) {
      return null;
    }
    try {
      final price = fiatConversionStore?.prices[currency];
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
      return _capped(token.symbol.toUpperCase());
    }
    return shortAddress(contractAddress);
  }

  String _capped(String text) {
    final characters = text.runes;
    if (characters.length <= _maxNameLength) {
      return text;
    }
    return "${String.fromCharCodes(characters.take(_maxNameLength))}…";
  }

  String formatExpiry(BigInt seconds) =>
      seconds > _maxTimestampSeconds ? S.current.wc_never : formatTimestamp(seconds);

  String formatTimestamp(BigInt seconds) {
    if (seconds <= BigInt.zero || seconds > _maxTimestampSeconds) {
      return seconds.toString();
    }
    final date = DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
    return DateFormat.yMMMd().add_Hm().format(date);
  }
}
