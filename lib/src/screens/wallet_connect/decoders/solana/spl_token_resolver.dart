import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

class SplTokenResolver {
  SplTokenResolver(this.appStore);

  final AppStore? appStore;

  Iterable<CryptoCurrency> walletKnownTokens() {
    final wallet = appStore?.wallet;
    if (wallet == null || solana == null) {
      return const [];
    }
    try {
      return solana!.getSPLTokenCurrencies(wallet);
    } catch (e) {
      printV("SplTokenResolver: walletKnownTokens failed: $e");
      return const [];
    }
  }

  Map<String, CryptoCurrency> trackedAndDefaultTokensByMint() {
    final result = <String, CryptoCurrency>{};
    for (final t in walletKnownTokens()) {
      final m = mintAddressOf(t);
      if (m == null || m.isEmpty) {
        continue;
      }
      result.putIfAbsent(m, () => t);
    }
    if (solana == null) {
      return result;
    }
    try {
      for (final t in solana!.getDefaultSPLTokens()) {
        final m = mintAddressOf(t);
        if (m == null || m.isEmpty) {
          continue;
        }
        result.putIfAbsent(m, () => t);
      }
    } catch (e) {
      printV("SplTokenResolver: getDefaultSPLTokens failed: $e");
    }
    return result;
  }

  String? mintAddressOf(CryptoCurrency token) {
    if (solana == null) {
      return null;
    }
    try {
      final m = solana!.getTokenAddress(token);
      return m.isEmpty ? null : m;
    } catch (e) {
      printV("SplTokenResolver: mintAddressOf failed for ${token.title}: $e");
      return null;
    }
  }

  Future<CryptoCurrency?> resolve(String mintAddress) async {
    final wallet = appStore?.wallet;
    if (wallet == null || solana == null) {
      return null;
    }

    try {
      final known = solana!.getSPLTokenCurrencies(wallet);
      for (final token in known) {
        final tokenAddress = solana!.getTokenAddress(token);
        if (tokenAddress.toLowerCase() == mintAddress.toLowerCase()) {
          return token;
        }
      }
    } catch (e) {
      printV("SplTokenResolver: failed to read wallet SPL list: $e");
    }

    try {
      return await solana!
          .getSPLToken(wallet, mintAddress)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      printV("SplTokenResolver: failed to fetch SPL metadata for $mintAddress: $e");
      return null;
    }
  }

  String shortAddress(String address) {
    if (address.length <= 10) {
      return address;
    }
    return "${address.substring(0, 4)}…${address.substring(address.length - 4)}";
  }

  String symbolFor(CryptoCurrency? token, String mintAddress) {
    if (token != null && token.title.isNotEmpty) {
      return token.title.toUpperCase();
    }
    return shortAddress(mintAddress);
  }

  int? decimalsFor(CryptoCurrency? token) => token?.decimals;

  BigInt balanceFor(CryptoCurrency? token) {
    if (token == null) {
      return BigInt.zero;
    }
    final wallet = appStore?.wallet;
    if (wallet == null) {
      return BigInt.zero;
    }
    try {
      final balance = wallet.balance[token];
      return balance?.available.amount ?? BigInt.zero;
    } catch (e) {
      printV("SplTokenResolver: balance lookup failed for ${token.title}: $e");
      return BigInt.zero;
    }
  }

  String formatAmount(BigInt rawAmount, int decimals) {
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

  String formatSol(BigInt lamports) => formatAmount(lamports, 9);
}
