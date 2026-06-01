import 'package:cake_wallet/solana/solana.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/utils/print_verbose.dart';

class SplTokenResolver {
  SplTokenResolver(this.appStore);

  final AppStore appStore;

  Future<CryptoCurrency?> resolve(String mintAddress) async {
    final wallet = appStore.wallet;
    if (wallet == null || solana == null) return null;

    try {
      final known = solana!.getSPLTokenCurrencies(wallet);
      for (final token in known) {
        final tokenAddress = solana!.getTokenAddress(token);
        if (tokenAddress.toLowerCase() == mintAddress.toLowerCase()) {
          return token;
        }
      }
    } catch (e) {
      printV('SplTokenResolver: failed to read wallet SPL list: $e');
    }

    try {
      return await solana!
          .getSPLToken(wallet, mintAddress)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
    } catch (e) {
      printV('SplTokenResolver: failed to fetch SPL metadata for $mintAddress: $e');
      return null;
    }
  }

  String shortAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
  }

  String symbolFor(CryptoCurrency? token, String mintAddress) {
    if (token != null && token.title.isNotEmpty) return token.title.toUpperCase();
    return shortAddress(mintAddress);
  }

  int decimalsFor(CryptoCurrency? token) => token?.decimals ?? 0;

  String formatAmount(BigInt rawAmount, int decimals) {
    if (decimals <= 0) return rawAmount.toString();
    final divisor = BigInt.from(10).pow(decimals);
    final whole = rawAmount ~/ divisor;
    final remainder = rawAmount % divisor;
    if (remainder == BigInt.zero) return whole.toString();
    final fractional = remainder.toString().padLeft(decimals, '0');
    final trimmed = fractional.replaceFirst(RegExp(r'0+$'), '');
    return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
  }

  String formatSol(BigInt lamports) {
    final sol = lamports.toDouble() / 1e9;
    if (sol == 0) return '0';
    if (sol >= 0.0001) return sol.toStringAsFixed(6);
    return sol.toStringAsExponential(4);
  }
}
