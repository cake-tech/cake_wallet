import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:http/http.dart' as http;

/// Shared keys and URL helpers for user-configured block explorers.
///
/// Lives in cw_core so both the app (settings UI, "view on explorer" links)
/// and wallet packages such as cw_bitcoin (mempool API calls) agree on the
/// same SharedPreferences keys without depending on each other.
class CustomBlockExplorers {
  CustomBlockExplorers._();

  /// Placeholder replaced with the transaction id in a link template.
  static const txIdPlaceholder = '{txid}';

  /// SharedPreferences key: base URL of a self-hosted mempool.space instance
  /// used for Bitcoin fee estimates and block timestamps.
  static const mempoolApiPrefsKey = 'custom_mempool_api_url';

  static const defaultMempoolApiClearnet = 'https://mempool.cakewallet.com';
  static const defaultMempoolApiOnion =
      'http://cakememcninjdqbaub3tp2iswuigxqtdoevnpgzkolmy4gvhrrsub3yd.onion';

  /// The transaction link for [explorer], or null when it is unusable.
  ///
  /// [explorer] is normally just the explorer's address, and `/tx/<txid>` is
  /// appended (the format used by mempool.space, dcrdata, the Monero onion
  /// explorer and most others). For anything else it can be a template with
  /// [txIdPlaceholder] where the transaction ID goes.
  static String? buildTxUrl(String? explorer, String txId) {
    if (explorer == null || !isValidExplorer(explorer)) return null;
    final trimmed = explorer.trim();
    final id = Uri.encodeComponent(txId);

    if (trimmed.contains(txIdPlaceholder)) return trimmed.replaceAll(txIdPlaceholder, id);
    return '${_trimTrailingSlashes(trimmed)}/tx/$id';
  }

  /// An explorer is an http(s) URL with a host: either an address with no
  /// query or fragment, or a template containing [txIdPlaceholder].
  static bool isValidExplorer(String value) {
    final trimmed = value.trim();
    if (trimmed.contains(txIdPlaceholder)) {
      return _isHttpUrlWithHost(trimmed.replaceAll(txIdPlaceholder, 'txid'));
    }
    if (!_isHttpUrlWithHost(trimmed)) return false;
    final uri = Uri.parse(trimmed);
    return !uri.hasQuery && !uri.hasFragment;
  }

  static String _trimTrailingSlashes(String value) {
    var result = value;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// A mempool base URL must be an http(s) URL with a host, no query or
  /// fragment, and no [txIdPlaceholder].
  static bool isValidBaseUrl(String value) {
    if (value.contains(txIdPlaceholder)) return false;
    final normalized = normalizeBaseUrl(value);
    if (!_isHttpUrlWithHost(normalized)) return false;
    final uri = Uri.parse(normalized);
    return !uri.hasQuery && !uri.hasFragment;
  }

  /// Trims whitespace, trailing slashes and a pasted `/api` or `/api/v1` suffix.
  static String normalizeBaseUrl(String value) {
    var result = _trimTrailingSlashes(value.trim());
    for (final suffix in const ['/api/v1', '/api']) {
      if (result.endsWith(suffix)) {
        result = result.substring(0, result.length - suffix.length);
        break;
      }
    }
    return _trimTrailingSlashes(result);
  }

  static bool isOnionHost(Uri uri) => uri.host.toLowerCase().endsWith('.onion');

  /// GETs a mempool API [path] from the user's instance, or the default server
  /// when none is configured (see [mempoolApiUris]). Goes through
  /// [ProxyWrapper], so it uses the built-in Tor whenever that is on.
  static Future<http.Response> fetchMempoolApi(
    String? customBase,
    String path, {
    bool withDefaultOnion = false,
    Duration timeout = const Duration(seconds: 15),
  }) {
    final uris = mempoolApiUris(customBase, path, withDefaultOnion: withDefaultOnion);
    return ProxyWrapper().get(clearnetUri: uris.clearnet, onionUri: uris.onion).timeout(timeout);
  }

  /// Resolves the clearnet and onion URIs for a mempool API [path]
  /// (for example `/api/v1/fees/recommended`).
  ///
  /// With a valid [customBase], only that server is returned, as the onion URI
  /// when its host is a `.onion` address and as the clearnet URI otherwise. It
  /// never falls back to Cake's server, so a misconfigured or unreachable
  /// instance fails the request instead of leaking it elsewhere.
  ///
  /// Without one, the defaults are returned; the default onion URI is only
  /// included when [withDefaultOnion] is set, matching the original call sites.
  static ({Uri? clearnet, Uri? onion}) mempoolApiUris(
    String? customBase,
    String path, {
    bool withDefaultOnion = false,
  }) {
    if (customBase != null && customBase.trim().isNotEmpty && isValidBaseUrl(customBase)) {
      final uri = Uri.parse('${normalizeBaseUrl(customBase)}$path');
      return isOnionHost(uri) ? (clearnet: null, onion: uri) : (clearnet: uri, onion: null);
    }

    return (
      clearnet: Uri.parse('$defaultMempoolApiClearnet$path'),
      onion: withDefaultOnion ? Uri.parse('$defaultMempoolApiOnion$path') : null,
    );
  }

  static bool _isHttpUrlWithHost(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.host.isNotEmpty;
  }
}
