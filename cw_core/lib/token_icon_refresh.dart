import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";

mixin TokenIconRefresh<T extends CryptoCurrency> {
  Future<bool> isTokenIconRefreshDisabled();

  Future<String?> fetchTokenIconUrl(T token);

  Future<void> saveTokenIconUrl(T token, String iconUrl);

  Future<void> refreshTokenIcons(List<T> tokens) async {
    try {
      if (await isTokenIconRefreshDisabled()) {
        return;
      }

      // Doing enabled tokens first so the ones shown on the dashboard get their icons soonest
      final sortedTokens = tokens.toList()
        ..sort((a, b) => (b.enabled ? 1 : 0).compareTo(a.enabled ? 1 : 0));

      for (final token in sortedTokens) {
        if (token.isPotentialScam || !token.hasPlaceholderIcon) {
          continue;
        }

        try {
          final iconUrl = await fetchTokenIconUrl(token);

          if (iconUrl == null || !iconUrl.startsWith("http")) {
            continue;
          }

          await saveTokenIconUrl(token, iconUrl);
        } catch (e) {
          printV("Failed to fetch icon url for ${token.title}: $e");
        }
      }
    } catch (e) {
      printV("Token icon refresh failed: $e");
    }
  }
}
