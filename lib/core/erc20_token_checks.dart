import "dart:convert";

import "package:cake_wallet/.secrets.g.dart" as secrets;
import "package:cake_wallet/entities/erc20_token_info_moralis.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/utils/proxy_wrapper.dart";

enum TokenCheckResult { safe, risky, failed, notCovered }

class Erc20TokenChecks {
  static Future<TokenCheckResult> moralisScamCheck(String contractAddress, int chainId) async {
    if (!evm!.isMoralisSupportedChain(chainId)) {
      return TokenCheckResult.notCovered;
    }

    final uri = Uri.https(
      "deep-index.moralis.io",
      "/api/v2.2/erc20/metadata",
      {
        "chain": evm!.getHexChainId(chainId),
        "addresses": contractAddress,
      },
    );

    try {
      final response = await ProxyWrapper().get(
        clearnetUri: uri,
        headers: {
          "Accept": "application/json",
          "X-API-Key": secrets.moralisApiKey,
        },
      ).timeout(const Duration(seconds: 15));

      final decodedResponse = jsonDecode(response.body);

      final tokenInfo = Erc20TokenInfoMoralis.fromJson(decodedResponse[0] as Map<String, dynamic>);

      // Based on analysis using Moralis internal metrics
      if (tokenInfo.possibleSpam == true) {
        return TokenCheckResult.risky;
      }

      // Tokens with a security score less than 40 are potentially risky
      if (tokenInfo.securityScore != null && tokenInfo.securityScore! < 40) {
        return TokenCheckResult.risky;
      }

      return TokenCheckResult.safe;
    } catch (e) {
      printV("Error while checking scam via moralis: ${e.toString()}");
      return TokenCheckResult.failed;
    }
  }

  static Future<TokenCheckResult> contractVerificationCheck(
    String contractAddress,
    int chainId,
  ) async {
    final uri = evm!.getContractSourceCodeUri(chainId, contractAddress);

    if (uri == null) {
      return TokenCheckResult.notCovered;
    }

    try {
      final response =
          await ProxyWrapper().get(clearnetUri: uri).timeout(const Duration(seconds: 15));

      final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;

      // Status 0 is an error such as a rate limit or a bad key, an unverified contract is status 1
      if (decodedResponse["status"] == "0") {
        printV("Contract verification check failed: ${decodedResponse["result"]}");
        return TokenCheckResult.failed;
      }

      final abi = decodedResponse["result"][0]["ABI"];
      final isBlockscout = uri.host != "api.etherscan.io";
      final isUnverified =
          abi == "Contract source code not verified" || (isBlockscout && abi == null);
      return isUnverified ? TokenCheckResult.risky : TokenCheckResult.safe;
    } catch (e) {
      printV("Error while checking contract verification: ${e.toString()}");
      return TokenCheckResult.failed;
    }
  }
}
