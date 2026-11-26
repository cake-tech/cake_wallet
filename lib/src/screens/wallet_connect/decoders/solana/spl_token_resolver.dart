import "package:cake_wallet/solana/solana.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_lookup_budget.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/solana/solana_program_ids.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

class SplTokenResolver {
  SplTokenResolver(this.appStore, this.budget);

  final AppStore? appStore;
  final SolanaLookupBudget budget;
  final _resolved = <String, Future<CryptoCurrency?>>{};

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

  bool isKnown(String mintAddress) {
    if (mintAddress == SolanaProgramIds.wrappedSolMint) {
      return true;
    }

    if (solana == null) {
      return false;
    }

    try {
      if (solana!.getDefaultSPLTokens().any((token) => mintAddressFor(token) == mintAddress)) {
        return true;
      }
    } catch (e) {
      printV("SplTokenResolver: getDefaultSPLTokens failed: $e");
    }

    return walletKnownTokens().any(
      (token) => mintAddressFor(token) == mintAddress && token.enabled && !token.isPotentialScam,
    );
  }

  String? mintAddressFor(CryptoCurrency token) {
    try {
      final address = solana!.getTokenAddress(token);
      return address.isEmpty ? null : address;
    } catch (e) {
      printV("SplTokenResolver: mintAddressFor failed for ${token.title}: $e");
      return null;
    }
  }

  Future<CryptoCurrency?> resolve(String mintAddress) =>
      _resolved.putIfAbsent(mintAddress, () => _lookUpToken(mintAddress));

  Future<CryptoCurrency?> _lookUpToken(String mintAddress) async {
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
      return await budget.run(
        () => solana!.getSPLToken(wallet, mintAddress),
        timeout: const Duration(seconds: 3),
      );
    } catch (e) {
      printV("SplTokenResolver: failed to fetch SPL metadata for $mintAddress: $e");
      return null;
    }
  }

  String symbolFor(CryptoCurrency? token, String mintAddress) {
    if (token != null && token.title.isNotEmpty && isKnown(mintAddress)) {
      return token.title.toUpperCase();
    }
    return shortAddress(mintAddress);
  }
}
