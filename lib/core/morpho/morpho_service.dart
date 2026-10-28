import "dart:convert";

import "package:cake_wallet/core/morpho/morpho_exceptions.dart";
import "package:cake_wallet/core/morpho/morpho_vault.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

class MorphoService {
  static const _apiHost = "api.morpho.org";

  // Net of fees, as a fraction (0.0123 = 1.23%).
  Future<double?> getApy() async {
    final uri = Uri.https(
      _apiHost,
      "/v1/vaults-v2/${MorphoVault.chainId}:${MorphoVault.vaultAddress}/apy-averages",
      {"lookback": "six_hours"},
    );
    final response = await ProxyWrapper().get(clearnetUri: uri);
    if (response.statusCode != 200) {
      throw MorphoApiException("${response.statusCode}: ${response.body}");
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body["data"] as Map<String, dynamic>;
    return (data["apy"] as num?)?.toDouble();
  }
}
